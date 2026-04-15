defmodule PhxIcons.Providers.SimpleIcons do
  @moduledoc false
  @behaviour PhxIcons.Provider

  @impl true
  def release_url(version) do
    "https://github.com/simple-icons/simple-icons/archive/refs/tags/#{version}.zip"
  end

  @impl true
  def svg_path(version, icon_name, _opts) do
    "simple-icons-#{version}/icons/#{icon_name}.svg"
  end
end
