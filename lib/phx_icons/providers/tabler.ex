defmodule PhxIcons.Providers.Tabler do
  @moduledoc false
  @behaviour PhxIcons.Provider

  @impl true
  def release_url(version) do
    "https://github.com/tabler/tabler-icons/archive/refs/tags/v#{version}.zip"
  end

  @impl true
  def svg_path(version, icon_name, _opts) do
    {base, style} = parse_variant(icon_name)
    "tabler-icons-#{version}/icons/#{style}/#{base}.svg"
  end

  defp parse_variant(name) do
    if String.ends_with?(name, "-filled") do
      {String.trim_trailing(name, "-filled"), "filled"}
    else
      {name, "outline"}
    end
  end
end
