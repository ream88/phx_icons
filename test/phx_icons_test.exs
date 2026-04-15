defmodule PhxIconsTest do
  use ExUnit.Case, async: true

  alias PhxIcons.Providers.Heroicons

  @icons_dir Path.join(System.tmp_dir!(), "phx_icons_test_#{System.unique_integer([:positive])}")

  setup_all do
    Application.put_env(:phx_icons, :providers, %{
      "heroicons" => {Heroicons, "2.2.0"},
      "heroicons-solid" => {Heroicons, "2.2.0", style: "solid"},
      "heroicons-mini" => {Heroicons, "2.2.0", style: "mini"},
      "heroicons-micro" => {Heroicons, "2.2.0", style: "micro"},
      "lucide" => {PhxIcons.Providers.Lucide, "0.469.0"},
      "tabler" => {PhxIcons.Providers.Tabler, "3.41.1"},
      "phosphor" => {PhxIcons.Providers.Phosphor, "2.0.8"},
      "simple-icons" => {PhxIcons.Providers.SimpleIcons, "16.16.0"},
      "flagpack" => {PhxIcons.Providers.Flagpack, "2.1.0"}
    })

    :ok
  end

  describe "SVG parsing" do
    test "extracts attributes" do
      svg = """
      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" d="M10.5 19.5 3 12m0 0 7.5-7.5M3 12h18" />
      </svg>
      """

      parsed = PhxIcons.SVG.parse(svg)

      assert parsed.view_box == "0 0 24 24"
      assert parsed.fill == "none"
      assert parsed.stroke == "currentColor"
      assert parsed.stroke_width == "1.5"
      assert parsed.inner =~ "M10.5 19.5"
    end

    test "defaults viewBox to 0 0 24 24" do
      svg = ~s[<svg xmlns="http://www.w3.org/2000/svg"><circle r="10" /></svg>]
      assert PhxIcons.SVG.parse(svg).view_box == "0 0 24 24"
    end
  end

  describe "compiler" do
    test "scans source files for icon references" do
      refs = PhxIcons.Compiler.scan_icon_refs()
      assert is_list(refs)
    end
  end

  describe "providers" do
    test "heroicons outline" do
      PhxIcons.Downloader.ensure_icons("heroicons", ["heart"], @icons_dir)
      assert_icon_downloaded("heroicons", "heart")
    end

    test "heroicons solid" do
      PhxIcons.Downloader.ensure_icons("heroicons-solid", ["heart"], @icons_dir)
      assert_icon_downloaded("heroicons-solid", "heart")
    end

    test "heroicons mini" do
      PhxIcons.Downloader.ensure_icons("heroicons-mini", ["heart"], @icons_dir)
      assert_icon_downloaded("heroicons-mini", "heart")
    end

    test "heroicons micro" do
      PhxIcons.Downloader.ensure_icons("heroicons-micro", ["heart"], @icons_dir)
      assert_icon_downloaded("heroicons-micro", "heart")
    end

    test "lucide" do
      PhxIcons.Downloader.ensure_icons("lucide", ["heart"], @icons_dir)
      assert_icon_downloaded("lucide", "heart")
    end

    test "tabler" do
      PhxIcons.Downloader.ensure_icons("tabler", ["heart"], @icons_dir)
      assert_icon_downloaded("tabler", "heart")
    end

    test "tabler filled" do
      PhxIcons.Downloader.ensure_icons("tabler", ["heart-filled"], @icons_dir)
      assert_icon_downloaded("tabler", "heart-filled")
    end

    test "phosphor regular" do
      PhxIcons.Downloader.ensure_icons("phosphor", ["heart"], @icons_dir)
      assert_icon_downloaded("phosphor", "heart")
    end

    test "phosphor duotone" do
      PhxIcons.Downloader.ensure_icons("phosphor", ["heart-duotone"], @icons_dir)
      assert_icon_downloaded("phosphor", "heart-duotone")
    end

    test "simple icons" do
      PhxIcons.Downloader.ensure_icons("simple-icons", ["github"], @icons_dir)
      assert_icon_downloaded("simple-icons", "github")
    end

    test "flagpack" do
      PhxIcons.Downloader.ensure_icons("flagpack", ["at"], @icons_dir)
      assert_icon_downloaded("flagpack", "at")
    end
  end

  defp assert_icon_downloaded(provider, name) do
    path = PhxIcons.Downloader.icon_path(@icons_dir, provider, name)
    assert File.exists?(path), "expected #{path} to exist"

    svg = PhxIcons.SVG.parse(File.read!(path))
    assert svg.view_box
    assert svg.inner =~ "<"
  end
end
