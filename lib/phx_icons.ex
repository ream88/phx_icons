defmodule PhxIcons do
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  use Phoenix.Component

  require Logger

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
        def icon(%{name: _name} = assigns) do
          PhxIcons.__unknown_icon__(unquote(Mix.env()), unquote(icons_dir), assigns)
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
  # In :dev, an unreferenced icon is downloaded on demand so it renders, but a
  # warning nudges the developer to reference it (or add it to :download) and
  # recompile — otherwise it won't ship. Every other env raises, just as before.
  def __unknown_icon__(:dev, icons_dir, %{name: name} = assigns) do
    case download_icon(name, icons_dir) do
      {:ok, svg} ->
        Logger.warning("""
        phx_icons: icon #{name} was fetched at runtime because it wasn't downloaded at compile time.

        Reference it statically (e.g. <.icon name="#{name}" />) or add it to the provider's \
        :download config, then recompile so it's available in production.\
        """)

        assigns =
          assigns
          |> Phoenix.Component.assign(:svg_attrs, svg.attrs)
          |> Phoenix.Component.assign(:inner, svg.inner)

        __render_svg__(assigns)

      :error ->
        raise unknown_icon_message(name)
    end
  end

  def __unknown_icon__(_env, _icons_dir, %{name: name}) do
    raise unknown_icon_message(name)
  end

  defp unknown_icon_message(name) do
    "unknown icon #{name}. Configure the provider with download: :all, {:also, list}, or a list."
  end

  defp download_icon(name, icons_dir) do
    with [provider, icon] when icon != "" <- String.split(name, ":", parts: 2),
         :ok <- safe_ensure_icon(provider, icon, icons_dir),
         path = PhxIcons.Downloader.icon_path(icons_dir, provider, icon),
         true <- File.exists?(path) do
      {:ok, PhxIcons.SVG.parse(File.read!(path))}
    else
      _ -> :error
    end
  end

  defp safe_ensure_icon(provider, icon, icons_dir) do
    PhxIcons.Downloader.ensure_icons(provider, [icon], icons_dir)
  rescue
    _ -> :error
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
