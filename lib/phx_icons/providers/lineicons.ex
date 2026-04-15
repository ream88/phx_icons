defmodule PhxIcons.Providers.Lineicons do
  @moduledoc false
  @behaviour PhxIcons.Provider

  @impl true
  def release_url(version) do
    "https://github.com/LineiconsHQ/Lineicons/archive/refs/heads/#{version}.zip"
  end

  @impl true
  def svg_path(version, icon_name, _opts) do
    "Lineicons-#{version}/assets/svgs/regular/#{icon_name}.svg"
  end
end
