defmodule PhxIcons.Compiler do
  @moduledoc false

  @icon_pattern ~r/name="([a-z][a-z0-9-]*):([a-z0-9][a-z0-9-]*)"/

  def ensure_icons(icons_dir) do
    scan_icon_refs()
    |> Enum.group_by(fn {provider, _} -> provider end, fn {_, icon} -> icon end)
    |> Task.async_stream(fn {provider, icons} ->
      PhxIcons.Downloader.ensure_icons(provider, Enum.uniq(icons), icons_dir)
    end)
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
    root = File.cwd!()
    icons_lib = Path.expand("../../lib", __DIR__)

    root
    |> Path.join("apps/*/lib/**/*.{heex,ex}")
    |> Path.wildcard()
    |> Enum.concat(Path.wildcard(Path.join(root, "lib/**/*.{heex,ex}")))
    |> Enum.reject(&String.starts_with?(&1, icons_lib))
  end

  defp extract_refs(path) do
    path
    |> File.read!()
    |> then(&Regex.scan(@icon_pattern, &1))
    |> Enum.map(fn [_, provider, icon] -> {provider, icon} end)
  end
end
