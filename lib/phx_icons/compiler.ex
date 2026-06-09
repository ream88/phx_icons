defmodule PhxIcons.Compiler do
  @moduledoc false

  alias Phoenix.LiveView.Tokenizer

  @initial_cont (case Application.spec(:phoenix_live_view, :vsn) do
                   nil ->
                     {:text, :enabled}

                   vsn ->
                     if Version.match?(List.to_string(vsn), "~> 0.20"),
                       do: :text,
                       else: {:text, :enabled}
                 end)

  def ensure_icons(icons_dir, opts \\ []) do
    root = Keyword.get_lazy(opts, :root, &project_root/0)
    providers = Application.get_env(:phx_icons, :providers, %{})

    providers
    |> Task.async_stream(
      fn {key, config} ->
        opts =
          case config do
            {_, _, opts} -> opts
            _ -> []
          end

        case download_icons(Keyword.get(opts, :download)) do
          :all -> PhxIcons.Downloader.ensure_all(key, icons_dir)
          {:icons, icons} -> PhxIcons.Downloader.ensure_icons(key, icons, icons_dir)
          :none -> :ok
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
      scan_keys
      |> scan_icon_refs(root)
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

  defp download_icons(:all), do: :all
  defp download_icons({:also, icons}) when is_list(icons), do: {:icons, icons}

  defp download_icons(download) when is_list(download) do
    if Keyword.keyword?(download) do
      case Keyword.fetch(download, :also) do
        {:ok, icons} when is_list(icons) -> {:icons, icons}
        _ -> {:icons, download}
      end
    else
      {:icons, download}
    end
  end

  defp download_icons(_), do: :none

  defp scan_icon_refs(provider_keys, root) do
    root
    |> source_files()
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
            {:sigil_H, _, [{:<<>>, _, [text]}, _]}, acc when is_binary(text) ->
              {nil, extract_refs_heex(text, provider_keys) ++ acc}

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
    case EEx.tokenize(content) do
      {:ok, eex_tokens} ->
        eex_tokens
        |> Enum.flat_map(fn
          {:text, text, _meta} ->
            tokenize_heex(to_string(text), provider_keys)

          {:expr, _marker, expr, _meta} ->
            extract_refs_ex(to_string(expr), provider_keys)

          _ ->
            []
        end)
        |> Enum.uniq()

      {:error, _} ->
        []
    end
  end

  defp tokenize_heex(text, provider_keys) do
    state = Tokenizer.init(0, "nofile", text, Phoenix.LiveView.HTMLEngine)

    {tokens, cont} =
      Tokenizer.tokenize(
        text,
        [line: 1, column: 1],
        [],
        @initial_cont,
        state
      )

    tokens = Tokenizer.finalize(tokens, "nofile", cont, text)

    Enum.flat_map(tokens, &extract_refs_from_token(&1, provider_keys))
  rescue
    _ -> []
  end

  # <.icon name="heroicons:heart" /> — direct icon component call
  defp extract_refs_from_token({:local_component, "icon", attrs, _meta}, provider_keys) do
    extract_name_attr(attrs, provider_keys)
  end

  # <Module.icon name="heroicons:heart" /> — remote icon component call. The
  # tokenizer emits the tag name as a plain string ("Some.Module.icon"), so match
  # the trailing ".icon" segment rather than a {module, function} tuple.
  defp extract_refs_from_token({:remote_component, name, attrs, _meta}, provider_keys)
       when is_binary(name) do
    if String.ends_with?(name, ".icon") do
      extract_name_attr(attrs, provider_keys)
    else
      extract_icon_attr(attrs, provider_keys)
    end
  end

  # Any other component with an "icon" attribute, e.g. <.empty icon="heroicons:inbox">
  defp extract_refs_from_token({:local_component, _name, attrs, _meta}, provider_keys) do
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

  defp source_files(root) do
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
