defmodule PhxIcons.Providers.Phosphor do
  @moduledoc false
  @behaviour PhxIcons.Provider

  @impl true
  def release_url(version) do
    "https://github.com/phosphor-icons/core/archive/refs/tags/v#{version}.zip"
  end

  @impl true
  def svg_path(version, icon_name, _opts) do
    {base, weight, file_suffix} = parse_weight(icon_name)
    "core-#{version}/assets/#{weight}/#{base}#{file_suffix}.svg"
  end

  defp parse_weight(name) do
    cond do
      String.ends_with?(name, "-bold") ->
        {String.trim_trailing(name, "-bold"), "bold", "-bold"}

      String.ends_with?(name, "-thin") ->
        {String.trim_trailing(name, "-thin"), "thin", "-thin"}

      String.ends_with?(name, "-light") ->
        {String.trim_trailing(name, "-light"), "light", "-light"}

      String.ends_with?(name, "-fill") ->
        {String.trim_trailing(name, "-fill"), "fill", "-fill"}

      String.ends_with?(name, "-duotone") ->
        {String.trim_trailing(name, "-duotone"), "duotone", "-duotone"}

      true ->
        {name, "regular", ""}
    end
  end
end
