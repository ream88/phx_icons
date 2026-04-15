defmodule PhxIcons.Providers.Lucide do
  @moduledoc false
  @behaviour PhxIcons.Provider

  @impl true
  def release_url(version) do
    "https://github.com/lucide-icons/lucide/releases/download/#{version}/lucide-icons-#{version}.zip"
  end

  @impl true
  def svg_path(_version, icon_name, _opts) do
    "icons/#{icon_name}.svg"
  end
end
