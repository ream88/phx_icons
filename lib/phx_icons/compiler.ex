defmodule PhxIcons.Compiler do
  @moduledoc false

  @icon_pattern ~r/name="([a-z][a-z0-9-]*):([a-z0-9][a-z0-9-]*)"/

  def ensure_icons(icons_dir) do
    providers = Application.get_env(:phx_icons, :providers, %{})

    {all_providers, scan_providers} =
      Enum.split_with(providers, fn {_key, config} ->
        opts =
          case config do
            {_, _, opts} -> opts
            _ -> []
          end

        Keyword.get(opts, :download) == :all
      end)

    refs =
      Enum.group_by(scan_icon_refs(), fn {provider, _} -> provider end, fn {_, icon} -> icon end)

    all_keys = Map.keys(refs) ++ Enum.map(all_providers, fn {key, _} -> key end)
    PhxIcons.Downloader.prefetch(Enum.uniq(all_keys))

    all_providers
    |> Task.async_stream(
      fn {key, _config} -> PhxIcons.Downloader.ensure_all(key, icons_dir) end,
      timeout: :infinity
    )
    |> Stream.run()

    scan_keys = MapSet.new(scan_providers, fn {key, _} -> key end)

    refs
    |> Enum.filter(fn {provider, _} -> MapSet.member?(scan_keys, provider) end)
    |> Task.async_stream(
      fn {provider, icons} ->
        PhxIcons.Downloader.ensure_icons(provider, Enum.uniq(icons), icons_dir)
      end,
      timeout: :infinity
    )
    |> Stream.run()

    :ok
  end

  def scan_icon_refs do
    source_files()
    |> Enum.flat_map(&extract_refs/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp source_files do
    root = project_root()
    icons_lib = Path.expand("../../lib", __DIR__)

    root
    |> Path.join("apps/*/lib/**/*.{heex,ex}")
    |> Path.wildcard()
    |> Enum.concat(Path.wildcard(Path.join(root, "lib/**/*.{heex,ex}")))
    |> Enum.reject(&String.starts_with?(&1, icons_lib))
  end

  defp project_root do
    File.cwd!()
    |> Stream.iterate(&Path.dirname/1)
    |> Stream.take(4)
    |> Enum.find(File.cwd!(), fn dir ->
      dir |> Path.join("apps/*/mix.exs") |> Path.wildcard() |> Enum.any?()
    end)
  end

  defp extract_refs(path) do
    path
    |> File.read!()
    |> then(&Regex.scan(@icon_pattern, &1))
    |> Enum.map(fn [_, provider, icon] -> {provider, icon} end)
  end
end
