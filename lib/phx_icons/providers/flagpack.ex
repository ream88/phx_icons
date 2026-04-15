defmodule PhxIcons.Providers.Flagpack do
  @moduledoc false
  @behaviour PhxIcons.Provider

  @impl true
  def release_url(version) do
    "https://github.com/Yummygum/flagpack-core/archive/refs/tags/v#{version}.zip"
  end

  @impl true
  def svg_path(version, icon_name, _opts) do
    "flagpack-core-#{version}/svg/l/#{String.upcase(icon_name)}.svg"
  end
end
