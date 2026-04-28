# PhxIcons

<!-- MDOC !-->

Icon library for Phoenix LiveView that scans your templates at compile time,
downloads only the icons you actually use, and inlines the SVGs as compiled
function clauses. Zero runtime overhead, no unused icons bundled, no Node.js
required.

## Installation

```elixir
def deps do
  [{:phx_icons, "~> 0.1.1"}]
end
```

## Quick start

Add `use PhxIcons` to your component module:

```elixir
defmodule MyAppWeb.CoreComponents do
  use Phoenix.Component
  use PhxIcons
end
```

Use icons in your templates:

```heex
<.icon name="heroicons:heart" class="size-6 text-red-500" />
<.icon name="lucide:search" class="size-4" />
<.icon name="flagpack:at" class="size-8" />
```

That's it. The icons are discovered, downloaded, and compiled automatically.

## How it works

1. `use PhxIcons` scans all `.heex` and `.ex` files for `name="provider:icon"`
   references at compile time
2. Missing icons are downloaded from the provider's GitHub release archive (ZIP
   files are cached in `/tmp/icons/`)
3. Each icon becomes a pattern-matched function clause with the SVG inlined
4. `__mix_recompile__?/0` triggers recompilation when new icon references appear

## Configuration

Configure providers in `config/config.exs`:

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
    "flagpack" => {PhxIcons.Providers.Flagpack, "2.1.0"},
    "lineicons" => {PhxIcons.Providers.Lineicons, "5.0"}
  }
```

You can also pre-download all icons from a provider or a specific list:

```elixir
config :phx_icons,
  providers: %{
    # Download all icons upfront
    "heroicons" => {PhxIcons.Providers.Heroicons, "2.2.0", download: :all},
    # Download a specific set
    "lucide" => {PhxIcons.Providers.Lucide, "0.469.0", download: ~w(search check x)}
  }
```

## Built-in providers

| Provider | Prefix | Variants |
|----------|--------|----------|
| [Heroicons](https://heroicons.com) | `heroicons` | outline (default), `-solid`, `-mini`, `-micro` |
| [Lucide](https://lucide.dev) | `lucide` | single style |
| [Tabler](https://tabler.io/icons) | `tabler` | outline (default), `-filled` |
| [Phosphor](https://phosphoricons.com) | `phosphor` | regular (default), `-bold`, `-thin`, `-light`, `-fill`, `-duotone` |
| [Simple Icons](https://simpleicons.org) | `simple-icons` | brand logos |
| [Flagpack](https://flagpack.xyz) | `flagpack` | country flags |
| [Lineicons](https://lineicons.com) | `lineicons` | single style |

```heex
<.icon name="heroicons:heart" class="size-6" />
<.icon name="heroicons-solid:heart" class="size-6" />
<.icon name="heroicons-mini:heart" class="size-5" />
<.icon name="tabler:star" class="size-6" />
<.icon name="tabler-filled:star" class="size-6" />
<.icon name="phosphor:bell" class="size-6" />
<.icon name="phosphor:bell-duotone" class="size-6" />
<.icon name="simple-icons:github" class="size-6 fill-current" />
<.icon name="flagpack:us" class="h-6 w-auto" />
<.icon name="lineicons:github" class="size-6" />
```

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

Then register it in your config:

```elixir
config :phx_icons,
  providers: %{
    "custom" => {MyApp.Providers.CustomIcons, "1.0.0"}
  }
```

## Testing

PhxIcons ships with test helpers to assert icons are rendered:

```elixir
import PhxIcons.Test

html = render_component(&MyAppWeb.CoreComponents.icon/1, name: "heroicons:heart")
assert_icon(html, "heroicons:heart")
refute_icon(html, "heroicons:x-mark")
```

<!-- MDOC !-->

## License

MIT — see [LICENSE](LICENSE).
