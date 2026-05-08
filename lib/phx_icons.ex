defmodule PhxIcons do
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

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
          raise "unknown icon #{name}. Configure the provider with download: :all, {:also, list}, or a list."
        end
      end

    svgs_hash = :erlang.md5(:erlang.term_to_binary(icon_paths))

    recompile =
      quote do
        def __mix_recompile__? do
          icons_dir = unquote(icons_dir)
          PhxIcons.Compiler.ensure_icons(icons_dir)

          svgs =
            icons_dir
            |> Path.join("*/*.svg")
            |> Path.wildcard()
            |> Enum.sort()

          :erlang.md5(:erlang.term_to_binary(svgs)) != unquote(svgs_hash)
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
    assigns = Phoenix.Component.assign(assigns, :inner, uniquify_ids(assigns.inner))

    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" {@svg_attrs} class={@class} {@rest}><%= {:safe, @inner} %></svg>
    """
  end

  defp uniquify_ids(inner) do
    case Regex.scan(~r/\bid="([^"]+)"/, inner) do
      [] ->
        inner

      matches ->
        prefix = "i#{System.unique_integer([:positive])}_"

        matches
        |> Enum.map(fn [_, id] -> id end)
        |> Enum.uniq()
        |> Enum.reduce(inner, fn id, acc -> String.replace(acc, id, prefix <> id) end)
    end
  end
end
