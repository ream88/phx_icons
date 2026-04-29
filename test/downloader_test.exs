defmodule PhxIcons.DownloaderTest do
  use ExUnit.Case, async: false

  alias PhxIcons.Downloader

  @svg ~s|<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M1 2"/></svg>|

  setup do
    {:ok, {_, zip_bytes}} =
      :zip.create(
        ~c"icons.zip",
        [{~c"heroicons-2.2.0/optimized/24/outline/heart.svg", @svg}],
        [:memory]
      )

    Application.put_env(:phx_icons, :providers, %{
      "heroicons" => {PhxIcons.Providers.Heroicons, "2.2.0"}
    })

    Application.put_env(:phx_icons, :backoff_base_ms, 0)

    cached_zip = Path.join([System.tmp_dir!(), "icons", "heroicons-2.2.0.zip"])
    File.rm_rf!(cached_zip)

    icons_dir = Path.join(System.tmp_dir!(), "phx_icons_dl_test_#{System.unique_integer([:positive])}")

    on_exit(fn ->
      Application.delete_env(:phx_icons, :http_client)
      Application.delete_env(:phx_icons, :backoff_base_ms)
      File.rm_rf!(cached_zip)
      File.rm_rf!(icons_dir)
    end)

    {:ok, icons_dir: icons_dir, zip_bytes: zip_bytes}
  end

  test "succeeds on first attempt", %{icons_dir: dir, zip_bytes: zip} do
    {:ok, calls} = Agent.start_link(fn -> 0 end)

    Application.put_env(:phx_icons, :http_client, fn _url ->
      Agent.update(calls, &(&1 + 1))
      {:ok, 200, zip}
    end)

    Downloader.ensure_icons("heroicons", ["heart"], dir)

    assert File.exists?(Downloader.icon_path(dir, "heroicons", "heart"))
    assert Agent.get(calls, & &1) == 1
  end

  test "retries on 5xx and eventually succeeds", %{icons_dir: dir, zip_bytes: zip} do
    {:ok, calls} = Agent.start_link(fn -> 0 end)

    Application.put_env(:phx_icons, :http_client, fn _url ->
      n = Agent.get_and_update(calls, &{&1, &1 + 1})
      if n < 2, do: {:ok, 503, ""}, else: {:ok, 200, zip}
    end)

    Downloader.ensure_icons("heroicons", ["heart"], dir)

    assert File.exists?(Downloader.icon_path(dir, "heroicons", "heart"))
    assert Agent.get(calls, & &1) == 3
  end

  test "retries on 429", %{icons_dir: dir, zip_bytes: zip} do
    {:ok, calls} = Agent.start_link(fn -> 0 end)

    Application.put_env(:phx_icons, :http_client, fn _url ->
      n = Agent.get_and_update(calls, &{&1, &1 + 1})
      if n < 1, do: {:ok, 429, ""}, else: {:ok, 200, zip}
    end)

    Downloader.ensure_icons("heroicons", ["heart"], dir)

    assert File.exists?(Downloader.icon_path(dir, "heroicons", "heart"))
    assert Agent.get(calls, & &1) == 2
  end

  test "retries on transport errors and eventually succeeds", %{icons_dir: dir, zip_bytes: zip} do
    {:ok, calls} = Agent.start_link(fn -> 0 end)

    Application.put_env(:phx_icons, :http_client, fn _url ->
      n = Agent.get_and_update(calls, &{&1, &1 + 1})
      if n < 1, do: {:error, :timeout}, else: {:ok, 200, zip}
    end)

    Downloader.ensure_icons("heroicons", ["heart"], dir)

    assert File.exists?(Downloader.icon_path(dir, "heroicons", "heart"))
    assert Agent.get(calls, & &1) == 2
  end

  test "fails fast on 404 without retrying", %{icons_dir: dir} do
    {:ok, calls} = Agent.start_link(fn -> 0 end)

    Application.put_env(:phx_icons, :http_client, fn _url ->
      Agent.update(calls, &(&1 + 1))
      {:ok, 404, ""}
    end)

    assert_raise RuntimeError, ~r/HTTP 404/, fn ->
      Downloader.ensure_icons("heroicons", ["heart"], dir)
    end

    assert Agent.get(calls, & &1) == 1
  end

  test "raises after exhausting retries on persistent 5xx", %{icons_dir: dir} do
    {:ok, calls} = Agent.start_link(fn -> 0 end)

    Application.put_env(:phx_icons, :http_client, fn _url ->
      Agent.update(calls, &(&1 + 1))
      {:ok, 503, ""}
    end)

    assert_raise RuntimeError, ~r/after 3 attempts.*HTTP 503/, fn ->
      Downloader.ensure_icons("heroicons", ["heart"], dir)
    end

    assert Agent.get(calls, & &1) == 3
  end

  test "raises after exhausting retries on persistent transport errors", %{icons_dir: dir} do
    {:ok, calls} = Agent.start_link(fn -> 0 end)

    Application.put_env(:phx_icons, :http_client, fn _url ->
      Agent.update(calls, &(&1 + 1))
      {:error, :nxdomain}
    end)

    assert_raise RuntimeError, ~r/after 3 attempts.*nxdomain/, fn ->
      Downloader.ensure_icons("heroicons", ["heart"], dir)
    end

    assert Agent.get(calls, & &1) == 3
  end

  test "raises if response body is not a valid zip", %{icons_dir: dir} do
    Application.put_env(:phx_icons, :http_client, fn _url ->
      {:ok, 200, "garbage not a zip"}
    end)

    assert_raise RuntimeError, ~r/not a valid zip archive/, fn ->
      Downloader.ensure_icons("heroicons", ["heart"], dir)
    end
  end
end
