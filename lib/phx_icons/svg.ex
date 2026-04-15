defmodule PhxIcons.SVG do
  @moduledoc false

  @ignored_attrs ~w(xmlns xmlns:xlink)

  defstruct [:inner, :attrs]

  def parse(svg_string) do
    svg_string = String.trim(svg_string)

    [_, attrs_str, inner] = Regex.run(~r/<svg\s+([^>]*)>(.*)<\/svg>/s, svg_string)

    attrs =
      ~r/([a-zA-Z][a-zA-Z0-9:-]*)="([^"]*)"/
      |> Regex.scan(attrs_str)
      |> Enum.map(fn [_, key, value] -> {key, value} end)
      |> Enum.reject(fn {key, _} -> key in @ignored_attrs end)

    attrs =
      if List.keyfind(attrs, "viewBox", 0),
        do: attrs,
        else: [{"viewBox", "0 0 24 24"} | attrs]

    %__MODULE__{inner: String.trim(inner), attrs: attrs}
  end
end
