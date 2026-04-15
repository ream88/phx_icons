defmodule PhxIcons.Providers.Heroicons do
  @moduledoc false
  @behaviour PhxIcons.Provider

  @impl true
  def release_url(version) do
    "https://github.com/tailwindlabs/heroicons/archive/refs/tags/v#{version}.zip"
  end

  @impl true
  def svg_path(version, icon_name, opts) do
    style = Keyword.get(opts, :style, "outline")

    {size, variant} =
      case style do
        "outline" -> {"24", "outline"}
        "solid" -> {"24", "solid"}
        "mini" -> {"20", "solid"}
        "micro" -> {"16", "solid"}
      end

    "heroicons-#{version}/optimized/#{size}/#{variant}/#{icon_name}.svg"
  end
end
