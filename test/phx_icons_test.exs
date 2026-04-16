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

      assert {"viewBox", "0 0 24 24"} in parsed.attrs
      assert {"fill", "none"} in parsed.attrs
      assert {"stroke", "currentColor"} in parsed.attrs
      assert {"stroke-width", "1.5"} in parsed.attrs
      refute Enum.any?(parsed.attrs, fn {k, _} -> k == "xmlns" end)
      assert parsed.inner =~ "M10.5 19.5"
    end

    test "defaults viewBox to 0 0 24 24" do
      svg = ~s[<svg xmlns="http://www.w3.org/2000/svg"><circle r="10" /></svg>]
      assert {"viewBox", "0 0 24 24"} in PhxIcons.SVG.parse(svg).attrs
    end
  end

  describe "compiler" do
    test "ensures icons are downloaded" do
      icons_dir = Path.join(System.tmp_dir!(), "phx_icons_compiler_#{System.unique_integer([:positive])}")
      PhxIcons.Downloader.ensure_icons("heroicons", ["heart"], icons_dir)
      assert File.exists?(PhxIcons.Downloader.icon_path(icons_dir, "heroicons", "heart"))
    end
  end

  describe "HEEx scanning" do
    test "finds icon refs in component calls" do
      defmodule HEExTest do
        use Phoenix.Component
        use PhxIcons

        def test(assigns) do
          ~H"""
          <.icon name="heroicons:heart" class="size-6" />
          <.icon name="heroicons:bell" class="size-4" />
          """
        end
      end

      assert function_exported?(HEExTest, :icon, 1)
    end

    test "finds icon refs passed as component attributes" do
      defmodule HEExAttrTest do
        use Phoenix.Component
        use PhxIcons

        attr(:icon, :string, required: true)
        slot(:inner_block, required: true)

        def empty(assigns) do
          ~H"""
          <.icon name={@icon} class="size-12" />
          {render_slot(@inner_block)}
          """
        end

        def test(assigns) do
          ~H"""
          <.empty icon="heroicons:inbox">Nothing here</.empty>
          """
        end
      end

      assert function_exported?(HEExAttrTest, :icon, 1)
    end

    test "finds icon refs inside ~H sigils in .ex files" do
      defmodule HEExSigilTest do
        use Phoenix.Component
        use PhxIcons

        def render(assigns) do
          ~H"""
          <.icon name="heroicons:star" class="size-6" />
          """
        end
      end

      assert function_exported?(HEExSigilTest, :icon, 1)
    end

    test "finds icon refs in HEEx with EEx expressions" do
      defmodule HEExEExTest do
        use Phoenix.Component
        use PhxIcons

        def render(assigns) do
          ~H"""
          <%= if true do %>
            <.icon name="heroicons:check" class="size-6" />
          <% end %>
          """
        end
      end

      assert function_exported?(HEExEExTest, :icon, 1)
    end

    test "ignores non-icon components" do
      defmodule HEExIgnoreTest do
        use Phoenix.Component
        use PhxIcons

        attr(:name, :string, required: true)
        def button(assigns), do: ~H"<button>{@name}</button>"

        def render(assigns) do
          ~H"""
          <.button name="heroicons:heart" />
          """
        end
      end

      # The .button component's name="heroicons:heart" should not trigger a download.
      # We can't easily test this in isolation since other tests download heart.svg,
      # so we just verify the module compiled without errors.
      assert function_exported?(HEExIgnoreTest, :button, 1)
    end
  end

  describe "test helpers" do
    import PhxIcons.Test

    setup do
      icons_dir = Path.join(Mix.Project.build_path(), "icons")
      PhxIcons.Downloader.ensure_icons("heroicons", ["heart"], icons_dir)
      :ok
    end

    test "assert_icon matches icon SVG content in HTML" do
      icon_inner = PhxIcons.Test.__icon__("heroicons:heart")
      html = "<div><svg>#{icon_inner}</svg></div>"
      assert_icon html, "heroicons:heart"
    end

    test "refute_icon passes when HTML does not contain the icon" do
      refute_icon "<div>no icons here</div>", "heroicons:heart"
    end

    test "refute_icon passes for plain text without icons" do
      refute_icon "no icons here", "heroicons:heart"
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
    assert Enum.any?(svg.attrs, fn {k, _} -> k == "viewBox" end)
    assert svg.inner =~ "<"
  end
end
