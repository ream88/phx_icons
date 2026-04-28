defmodule PhxIcons.MixProject do
  use Mix.Project

  @version "0.1.1"
  @source_url "https://github.com/ream88/phx_icons"

  def project do
    [
      app: :phx_icons,
      version: @version,
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "PhxIcons",
      description:
        "Dynamic icon library for Phoenix LiveView. Auto-discovers, downloads, and inlines SVG icons from multiple providers at compile time.",
      package: package(),
      docs: docs(),
      source_url: @source_url
    ]
  end

  def application do
    [
      extra_applications: [:logger, :inets, :ssl, :public_key]
    ]
  end

  defp deps do
    [
      {:phoenix_live_view, "~> 0.20 or ~> 1.0"},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:styler, "~> 1.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Mario Uher"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib priv/icons/.gitkeep .formatter.exs mix.exs README.md CHANGELOG.md LICENSE)
    ]
  end

  defp docs do
    [
      source_ref: "v#{@version}"
    ]
  end
end
