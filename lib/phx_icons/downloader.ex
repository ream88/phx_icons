defmodule PhxIcons.Downloader do
  @moduledoc false

  @cache_dir Path.join(System.tmp_dir!(), "icons")

  def prefetch(provider_keys) do
    provider_keys
    |> Enum.map(fn key -> provider_config!(key) end)
    |> Enum.uniq_by(fn {module, version, _} -> {module, version} end)
    |> Enum.each(fn {module, version, _} -> ensure_downloaded(module, version) end)
  end

  def ensure_icons(provider_key, icon_names, icons_dir) do
    {module, version, opts} = provider_config!(provider_key)

    missing =
      Enum.reject(icon_names, fn name ->
        File.exists?(icon_path(icons_dir, provider_key, name))
      end)

    if missing != [] do
      zip_path = ensure_downloaded(module, version)

      Enum.each(missing, fn name ->
        svg_path = module.svg_path(version, name, opts)
        extract_icon(zip_path, svg_path, name, icons_dir, provider_key)
      end)
    end

    :ok
  end

  def ensure_all(provider_key, icons_dir) do
    {module, version, opts} = provider_config!(provider_key)
    zip_path = ensure_downloaded(module, version)
    dest_dir = Path.join(icons_dir, to_string(provider_key))

    if File.exists?(dest_dir) && File.ls!(dest_dir) != [] do
      :ok
    else
      folder = version |> module.svg_path("__dummy__", opts) |> Path.dirname()
      folder_prefix = String.to_charlist(folder <> "/")

      {:ok, files} = :zip.list_dir(String.to_charlist(zip_path))

      svgs =
        files
        |> Enum.filter(fn
          {:zip_file, name, _, _, _, _} ->
            name_str = to_string(name)
            String.starts_with?(name_str, to_string(folder_prefix)) && String.ends_with?(name_str, ".svg")

          _ ->
            false
        end)
        |> Enum.map(fn {:zip_file, name, _, _, _, _} -> name end)

      File.mkdir_p!(dest_dir)

      case :zip.extract(String.to_charlist(zip_path), [{:file_list, svgs}, :memory]) do
        {:ok, extracted} ->
          for {name, content} <- extracted do
            icon_name = name |> to_string() |> Path.basename(".svg") |> String.downcase()
            File.write!(Path.join(dest_dir, "#{icon_name}.svg"), content)
          end

          for {alias_name, source_name} <- Keyword.get(opts, :aliases, %{}) do
            source = Path.join(dest_dir, "#{source_name}.svg")
            dest = Path.join(dest_dir, "#{alias_name}.svg")
            if File.exists?(source) && !File.exists?(dest), do: File.cp!(source, dest)
          end

        {:error, reason} ->
          raise "PhxIcons: failed to extract all from #{provider_key} (#{inspect(reason)})"
      end

      :ok
    end
  end

  def icon_path(icons_dir, provider_key, icon_name) do
    Path.join([icons_dir, to_string(provider_key), "#{icon_name}.svg"])
  end

  defp ensure_downloaded(module, version) do
    cache_key =
      module
      |> Module.split()
      |> List.last()
      |> Macro.underscore()

    File.mkdir_p!(@cache_dir)
    zip_path = Path.join(@cache_dir, "#{cache_key}-#{version}.zip")

    if !(File.exists?(zip_path) && valid_zip?(zip_path)) do
      download!(module.release_url(version), zip_path)
    end

    zip_path
  end

  defp valid_zip?(path) do
    match?({:ok, _}, :zip.list_dir(String.to_charlist(path)))
  end

  defp download!(url, dest) do
    :ssl.start()
    :inets.start()

    http_opts = [
      ssl: [
        verify: :verify_peer,
        cacerts: :public_key.cacerts_get(),
        depth: 3,
        customize_hostname_check: [
          match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
        ]
      ],
      autoredirect: true,
      timeout: 120_000
    ]

    tmp_dest = dest <> ".#{System.unique_integer([:positive])}.part"

    case :httpc.request(:get, {String.to_charlist(url), []}, http_opts, body_format: :binary) do
      {:ok, {{_, 200, _}, _headers, body}} ->
        File.write!(tmp_dest, body)

        if valid_zip?(tmp_dest) do
          File.rename!(tmp_dest, dest)
        else
          File.rm(tmp_dest)
          raise "PhxIcons: downloaded file from #{url} is not a valid zip archive"
        end

      {:ok, {{_, status, _}, _, _}} ->
        raise "PhxIcons: failed to download #{url} (HTTP #{status})"

      {:error, reason} ->
        raise "PhxIcons: failed to download #{url} (#{inspect(reason)})"
    end
  end

  defp extract_icon(zip_path, svg_path, icon_name, icons_dir, provider_key) do
    file_in_zip = String.to_charlist(svg_path)
    dest_dir = Path.join(icons_dir, to_string(provider_key))
    File.mkdir_p!(dest_dir)

    case :zip.extract(String.to_charlist(zip_path), [{:file_list, [file_in_zip]}, :memory]) do
      {:ok, [{_, content}]} ->
        File.write!(Path.join(dest_dir, "#{icon_name}.svg"), content)

      {:ok, []} ->
        raise "PhxIcons: #{provider_key}:#{icon_name} not found in archive (looked for #{file_in_zip})"

      {:error, reason} ->
        raise "PhxIcons: failed to extract #{icon_name} (#{inspect(reason)})"
    end
  end

  defp provider_config!(provider_key) do
    providers = Application.get_env(:phx_icons, :providers, %{})
    key = to_string(provider_key)

    case Map.get(providers, key) do
      {module, version} -> {module, version, []}
      {module, version, opts} -> {module, version, opts}
      nil -> raise "PhxIcons: unknown provider #{key}. Configure it in :phx_icons, :providers"
    end
  end
end
