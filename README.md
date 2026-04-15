# PhxIcons

Dynamic icon library for Phoenix LiveView. Use icons from multiple providers —
they're automatically discovered from your templates, downloaded, and inlined as
SVG at compile time.

## Features

- **Zero config icon discovery** — just use `<.icon name="heroicons:heart" />` in
  a template and the icon is downloaded and compiled automatically
- **Multiple providers** — Heroicons, Lucide, Tabler, Phosphor, Simple Icons, Flagpack
  out of the box, with a simple behaviour to add your own
- **Compile-time inlining** — icons are baked into your compiled modules as
  pattern-matched function clauses, zero runtime overhead
- **Only downloads what you use** — zip archives are cached, individual SVGs
  extracted on demand

## Installation

Add `phx_icons` to your dependencies:

```elixir
def deps do
  [{:phx_icons, "~> 0.1.0"}]
end
```

## Configuration

Configure your providers in `config/config.exs`:

```elixir
config :phx_icons,
  providers: %{
    "heroicons" => {PhxIcons.Providers.Heroicons, "2.2.0"},
    "heroicons-solid" => {PhxIcons.Providers.Heroicons, "2.2.0", style: "solid"},
    "heroicons-mini" => {PhxIcons.Providers.Heroicons, "2.2.0", style: "mini"},
    "heroicons-micro" => {PhxIcons.Providers.Heroicons, "2.2.0", style: "micro"},
    "lucide" => {PhxIcons.Providers.Lucide, "0.469.0"},
    "tabler" => {PhxIcons.Providers.Tabler, "3.41.1"},
    "phosphor" => {PhxIcons.Providers.Phosphor, "2.0.8"},
    "simple-icons" => {PhxIcons.Providers.SimpleIcons, "16.16.0"},
    "flagpack" => {PhxIcons.Providers.Flagpack, "2.1.0"}
  }
```

## Usage

Add `use PhxIcons` to your component module:

```elixir
defmodule MyAppWeb.CoreComponents do
  use Phoenix.Component
  use PhxIcons

  # icon/1 is now available with all discovered icons compiled in
end
```

Then use icons in your templates:

```heex
<.icon name="heroicons:heart" class="size-6" />
<.icon name="heroicons-mini:heart" class="size-5" />
<.icon name="lucide:check" class="size-6" />
<.icon name="tabler:star" class="size-6" />
<.icon name="phosphor:bell" class="size-6" />
<.icon name="phosphor:bell-duotone" class="size-6" />
<.icon name="simple-icons:github" class="size-6 fill-current" />
<.icon name="flagpack:us" class="h-6 w-auto" />
```

## How it works

1. The `use PhxIcons` macro scans all `.heex` and `.ex` files for
   `name="provider:icon"` references
2. Missing icons are downloaded from the provider's GitHub release archive
3. A function clause is generated per icon with the SVG inlined
4. `__mix_recompile__?/0` triggers recompilation when new icon references appear

## Built-in providers

| Provider | Prefix | Variants |
|----------|--------|----------|
| [Heroicons](https://heroicons.com) | `heroicons` | outline (default), `-solid`, `-mini`, `-micro` |
| [Lucide](https://lucide.dev) | `lucide` | single style |
| [Tabler](https://tabler.io/icons) | `tabler` | outline (default), `-filled` |
| [Phosphor](https://phosphoricons.com) | `phosphor` | regular (default), `-bold`, `-thin`, `-light`, `-fill`, `-duotone` |
| [Simple Icons](https://simpleicons.org) | `simple-icons` | brand logos, single style |
| [Flagpack](https://flagpack.xyz) | `flagpack` | country flags |

## Custom providers

Implement the `PhxIcons.Provider` behaviour:

```elixir
defmodule MyApp.Providers.CustomIcons do
  @behaviour PhxIcons.Provider

  @impl true
  def release_url(version) do
    "https://github.com/org/repo/archive/refs/tags/v#{version}.zip"
  end

  @impl true
  def svg_path(version, icon_name, _opts) do
    "repo-#{version}/icons/#{icon_name}.svg"
  end
end
```

Then add it to your config:

```elixir
config :phx_icons,
  providers: %{
    "custom" => {MyApp.Providers.CustomIcons, "1.0.0"}
  }
```

## License

MIT — see [LICENSE](LICENSE).
