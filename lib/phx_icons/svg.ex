defmodule PhxIcons.SVG do
  @moduledoc false

  defstruct [:inner, :view_box, :fill, :stroke, :stroke_width, :stroke_linecap, :stroke_linejoin]

  def parse(svg_string) do
    svg_string = String.trim(svg_string)

    [_, attrs_str, inner] = Regex.run(~r/<svg\s+([^>]*)>(.*)<\/svg>/s, svg_string)

    %__MODULE__{
      inner: String.trim(inner),
      view_box: extract_attr(attrs_str, "viewBox") || "0 0 24 24",
      fill: extract_attr(attrs_str, "fill"),
      stroke: extract_attr(attrs_str, "stroke"),
      stroke_width: extract_attr(attrs_str, "stroke-width"),
      stroke_linecap: extract_attr(attrs_str, "stroke-linecap"),
      stroke_linejoin: extract_attr(attrs_str, "stroke-linejoin")
    }
  end

  defp extract_attr(attrs_str, name) do
    case Regex.run(~r/#{Regex.escape(name)}="([^"]*)"/, attrs_str) do
      [_, value] -> value
      nil -> nil
    end
  end
end
