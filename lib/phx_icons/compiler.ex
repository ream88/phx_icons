defmodule PhxIcons.Compiler do
  @moduledoc false

  def ensure_icons(icons_dir) do
    providers = Application.get_env(:phx_icons, :providers, %{})

    providers
    |> Task.async_stream(
      fn {key, config} ->
        opts =
          case config do
            {_, _, opts} -> opts
            _ -> []
          end

        case Keyword.get(opts, :download) do
          :all -> PhxIcons.Downloader.ensure_all(key, icons_dir)
          icons when is_list(icons) -> PhxIcons.Downloader.ensure_icons(key, icons, icons_dir)
          _ -> :ok
        end
      end,
      timeout: :infinity
    )
    |> Stream.run()

    scan_keys =
      providers
      |> Enum.reject(fn {_key, config} ->
        opts =
          case config do
            {_, _, opts} -> opts
            _ -> []
          end

        Keyword.get(opts, :download) == :all
      end)
      |> MapSet.new(fn {key, _} -> key end)

    if MapSet.size(scan_keys) > 0 do
      scan_icon_refs(scan_keys)
      |> Enum.group_by(fn {provider, _} -> provider end, fn {_, icon} -> icon end)
      |> Task.async_stream(
        fn {provider, icons} ->
          PhxIcons.Downloader.ensure_icons(provider, Enum.uniq(icons), icons_dir)
        end,
        timeout: :infinity
      )
      |> Stream.run()
    end

    :ok
  end

  defp scan_icon_refs(provider_keys) do
    source_files()
    |> Enum.flat_map(fn path ->
      content = File.read!(path)

      if String.ends_with?(path, ".heex") do
        extract_refs_heex(content, provider_keys)
      else
        extract_refs_ex(content, provider_keys)
      end
    end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp extract_refs_ex(content, provider_keys) do
    case Code.string_to_quoted(content, columns: true) do
      {:ok, ast} ->
        {_, refs} =
          Macro.prewalk(ast, [], fn
            node, acc when is_binary(node) ->
              case parse_icon_ref(node, provider_keys) do
                {:ok, ref} -> {node, [ref | acc]}
                :skip -> {node, acc}
              end

            node, acc ->
              {node, acc}
          end)

        refs

      {:error, _} ->
        []
    end
  end

  defp extract_refs_heex(content, provider_keys) do
    state =
      Phoenix.LiveView.Tokenizer.init(
        0,
        "nofile",
        content,
        Phoenix.LiveView.HTMLEngine
      )

    case Phoenix.LiveView.Tokenizer.tokenize(
           content,
           [line: 1, column: 1],
           [],
           {:text, :enabled},
           state
         ) do
      {tokens, cont} ->
        tokens = Phoenix.LiveView.Tokenizer.finalize(tokens, "nofile", cont, content)

        tokens
        |> Enum.flat_map(&extract_refs_from_token(&1, provider_keys))
        |> Enum.uniq()

      _ ->
        []
    end
  end

  # <.icon name="heroicons:heart" /> — direct icon component call
  defp extract_refs_from_token({:local_component, "icon", attrs, _meta}, provider_keys) do
    extract_name_attr(attrs, provider_keys)
  end

  # <Module.icon name="heroicons:heart" /> — remote icon component call
  defp extract_refs_from_token({:remote_component, {_mod, "icon"}, attrs, _meta}, provider_keys) do
    extract_name_attr(attrs, provider_keys)
  end

  # Any component with an "icon" attribute, e.g. <.empty icon="heroicons:inbox">
  defp extract_refs_from_token({type, _name, attrs, _meta}, provider_keys)
       when type in [:local_component, :remote_component] do
    extract_icon_attr(attrs, provider_keys)
  end

  defp extract_refs_from_token(_, _), do: []

  defp extract_name_attr(attrs, provider_keys) do
    Enum.flat_map(attrs, fn
      {"name", {:string, value, _}, _} ->
        case parse_icon_ref(value, provider_keys) do
          {:ok, ref} -> [ref]
          :skip -> []
        end

      _ ->
        []
    end)
  end

  defp extract_icon_attr(attrs, provider_keys) do
    Enum.flat_map(attrs, fn
      {"icon", {:string, value, _}, _} ->
        case parse_icon_ref(value, provider_keys) do
          {:ok, ref} -> [ref]
          :skip -> []
        end

      _ ->
        []
    end)
  end

  defp parse_icon_ref(string, provider_keys) do
    case String.split(string, ":", parts: 2) do
      [provider, icon] when byte_size(icon) > 0 ->
        if MapSet.member?(provider_keys, provider) &&
             Regex.match?(~r/^[a-z0-9][a-z0-9-]*$/, icon) do
          {:ok, {provider, icon}}
        else
          :skip
        end

      _ ->
        :skip
    end
  end

  defp source_files do
    root = project_root()
    icons_lib = Path.expand("../../lib", __DIR__)

    root
    |> Path.join("apps/*/lib/**/*.{heex,ex}")
    |> Path.wildcard()
    |> Enum.concat(Path.wildcard(Path.join(root, "lib/**/*.{heex,ex}")))
    |> Enum.reject(&String.starts_with?(&1, icons_lib))
  end

  defp project_root do
    File.cwd!()
    |> Stream.iterate(&Path.dirname/1)
    |> Stream.take(4)
    |> Enum.find(File.cwd!(), fn dir ->
      dir |> Path.join("apps/*/mix.exs") |> Path.wildcard() |> Enum.any?()
    end)
  end
end
