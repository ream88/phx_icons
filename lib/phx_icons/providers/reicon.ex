defmodule PhxIcons.Providers.Reicon do
  @moduledoc false
  @behaviour PhxIcons.Provider

  @impl true
  def release_url(version) do
    # Reicon publishes no release assets; `version` is a git ref (commit SHA
    # or branch) pointing at the SVG bundle committed in the repo.
    "https://raw.githubusercontent.com/dqev/reicon/#{version}/public/reicon-icons.zip"
  end

  @impl true
  def svg_path(_version, icon_name, opts) do
    "#{Keyword.get(opts, :style, "outline")}/#{icon_name}.svg"
  end

  # The bundle hardcodes black fills, which would ignore CSS color classes.
  @impl true
  def transform(svg) do
    String.replace(svg, ~s(fill="#000000"), ~s(fill="currentColor"))
  end
end
