defmodule PhxIcons do
  @moduledoc """
  Dynamic icon component for Phoenix LiveView.

  Icons are referenced by `provider:name` and resolved at compile time. In dev,
  unknown icons are fetched on-the-fly via `PhxIcons.Server`. In prod, a missing
  icon raises at runtime.

  ## Usage

  Add `use PhxIcons` to a module that already `use Phoenix.Component`:

      defmodule MyAppWeb.CoreComponents do
        use Phoenix.Component
        use PhxIcons

        # icon/1 is now available with all discovered icons compiled in
      end

  Then in templates:

      <.icon name="heroicons:arrow-left" class="size-5" />
      <.icon name="lucide:check" class="size-4" />

  ## How it works

  1. The `use PhxIcons` macro scans source files for `name="provider:icon"` references
  2. Missing icons are downloaded from the provider's release archive
  3. A function clause is generated per icon with the SVG inlined
  4. `__mix_recompile__?/0` triggers recompilation when references change
  """

  use Phoenix.Component

  defmacro __using__(_opts) do
    icons_dir = Path.join(Mix.Project.build_path(), "icons")
    PhxIcons.Compiler.ensure_icons(icons_dir)

    icon_paths = icons_dir |> Path.join("*/*.svg") |> Path.wildcard() |> Enum.sort()

    clauses =
      for svg_path <- icon_paths do
        provider = svg_path |> Path.relative_to(icons_dir) |> Path.split() |> hd()
        icon_name = Path.basename(svg_path, ".svg")
        full_name = "#{provider}:#{icon_name}"
        svg = PhxIcons.SVG.parse(File.read!(svg_path))

        quote do
          @external_resource unquote(svg_path)

          def icon(%{name: unquote(full_name)} = assigns) do
            assigns =
              assigns
              |> Phoenix.Component.assign(:svg_attrs, unquote(Macro.escape(svg.attrs)))
              |> Phoenix.Component.assign(:inner, unquote(svg.inner))

            PhxIcons.__render_svg__(assigns)
          end
        end
      end

    fallback =
      quote do
        def icon(%{name: name}) do
          raise "PhxIcons: unknown icon #{name}. Ensure it is referenced in a template and compile."
        end
      end

    refs_hash = :erlang.md5(:erlang.term_to_binary(PhxIcons.Compiler.scan_icon_refs()))
    svgs_hash = :erlang.md5(:erlang.term_to_binary(icon_paths))

    recompile =
      quote do
        def __mix_recompile__? do
          refs_hash =
            PhxIcons.Compiler.scan_icon_refs()
            |> :erlang.term_to_binary()
            |> :erlang.md5()

          svgs =
            unquote(icons_dir)
            |> Path.join("*/*.svg")
            |> Path.wildcard()
            |> Enum.sort()

          svgs_hash = :erlang.md5(:erlang.term_to_binary(svgs))

          refs_hash != unquote(refs_hash) or svgs_hash != unquote(svgs_hash)
        end
      end

    quote do
      attr(:name, :string, required: true)
      attr(:class, :any, default: nil)
      attr(:rest, :global)

      unquote_splicing(clauses)
      unquote(fallback)
      unquote(recompile)
    end
  end

  @doc false
  def __render_svg__(assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" {@svg_attrs} class={@class} {@rest}><%= {:safe, @inner} %></svg>
    """
  end
end
