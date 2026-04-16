defmodule PhxIcons.Test do
  @moduledoc """
  Test helpers for asserting icon presence in rendered HTML.

  Requires either `lazy_html` or `floki` as a dependency.

  ## Usage

      import PhxIcons.Test

      assert_icon render(view), "heroicons:heart"
      refute_icon render(view), "heroicons:heart"
  """

  import ExUnit.Assertions

  @doc """
  Asserts that the rendered HTML contains the given icon.
  """
  defmacro assert_icon(html, name) do
    quote do
      assert unquote(html) =~ PhxIcons.Test.__icon__(unquote(name))
    end
  end

  @doc """
  Refutes that the rendered HTML contains the given icon.
  """
  defmacro refute_icon(html, name) do
    quote do
      refute unquote(html) =~ PhxIcons.Test.__icon__(unquote(name))
    end
  end

  @doc false
  def __icon__(name) do
    [provider, icon_name] = String.split(name, ":", parts: 2)
    icons_dir = Path.join(Mix.Project.build_path(), "icons")
    svg_path = Path.join([icons_dir, provider, "#{icon_name}.svg"])

    svg = PhxIcons.SVG.parse(File.read!(svg_path))

    case Regex.run(~r/\bd="([^"]+)"/, svg.inner) do
      [_, d] -> d
      nil -> svg.inner
    end
  end
end
