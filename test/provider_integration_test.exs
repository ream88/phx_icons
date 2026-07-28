defmodule PhxIcons.ProviderIntegrationTest do
  # Real downloads from real release URLs — catches providers changing their
  # zip layout or URL scheme. Excluded by default; run with:
  #
  #     mix test --include network
  #
  # async: false because it swaps the global provider config and http_client.
  use ExUnit.Case, async: false

  @moduletag :network

  alias PhxIcons.Providers.Heroicons

  @icons_dir Path.join(System.tmp_dir!(), "phx_icons_integration_#{System.unique_integer([:positive])}")

  setup_all do
    Application.delete_env(:phx_icons, :http_client)

    Application.put_env(:phx_icons, :providers, %{
      "heroicons" => {Heroicons, "2.2.0"},
      "heroicons-solid" => {Heroicons, "2.2.0", style: "solid"},
      "heroicons-mini" => {Heroicons, "2.2.0", style: "mini"},
      "heroicons-micro" => {Heroicons, "2.2.0", style: "micro"},
      "lucide" => {PhxIcons.Providers.Lucide, "0.469.0"},
      "tabler" => {PhxIcons.Providers.Tabler, "3.41.1"},
      "phosphor" => {PhxIcons.Providers.Phosphor, "2.0.8"},
      "simple-icons" => {PhxIcons.Providers.SimpleIcons, "16.16.0"},
      "flagpack" => {PhxIcons.Providers.Flagpack, "2.1.0"}
    })

    on_exit(fn -> File.rm_rf!(@icons_dir) end)

    :ok
  end

  test "heroicons outline" do
    PhxIcons.Downloader.ensure_icons("heroicons", ["heart"], @icons_dir)
    assert_icon_downloaded("heroicons", "heart")
  end

  test "heroicons solid" do
    PhxIcons.Downloader.ensure_icons("heroicons-solid", ["heart"], @icons_dir)
    assert_icon_downloaded("heroicons-solid", "heart")
  end

  test "heroicons mini" do
    PhxIcons.Downloader.ensure_icons("heroicons-mini", ["heart"], @icons_dir)
    assert_icon_downloaded("heroicons-mini", "heart")
  end

  test "heroicons micro" do
    PhxIcons.Downloader.ensure_icons("heroicons-micro", ["heart"], @icons_dir)
    assert_icon_downloaded("heroicons-micro", "heart")
  end

  test "lucide" do
    PhxIcons.Downloader.ensure_icons("lucide", ["heart"], @icons_dir)
    assert_icon_downloaded("lucide", "heart")
  end

  test "tabler" do
    PhxIcons.Downloader.ensure_icons("tabler", ["heart"], @icons_dir)
    assert_icon_downloaded("tabler", "heart")
  end

  test "tabler filled" do
    PhxIcons.Downloader.ensure_icons("tabler", ["heart-filled"], @icons_dir)
    assert_icon_downloaded("tabler", "heart-filled")
  end

  test "phosphor regular" do
    PhxIcons.Downloader.ensure_icons("phosphor", ["heart"], @icons_dir)
    assert_icon_downloaded("phosphor", "heart")
  end

  test "phosphor duotone" do
    PhxIcons.Downloader.ensure_icons("phosphor", ["heart-duotone"], @icons_dir)
    assert_icon_downloaded("phosphor", "heart-duotone")
  end

  test "simple icons" do
    PhxIcons.Downloader.ensure_icons("simple-icons", ["github"], @icons_dir)
    assert_icon_downloaded("simple-icons", "github")
  end

  test "flagpack" do
    PhxIcons.Downloader.ensure_icons("flagpack", ["at"], @icons_dir)
    assert_icon_downloaded("flagpack", "at")
  end

  defp assert_icon_downloaded(provider, name) do
    path = PhxIcons.Downloader.icon_path(@icons_dir, provider, name)
    assert File.exists?(path), "expected #{path} to exist"

    svg = PhxIcons.SVG.parse(File.read!(path))
    assert Enum.any?(svg.attrs, fn {k, _} -> k == "viewBox" end)
    assert svg.inner =~ "<"
  end
end
