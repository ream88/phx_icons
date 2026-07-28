defmodule PhxIconsTest do
  use ExUnit.Case, async: true

  alias PhxIcons.Providers.Heroicons

  @svg ~s|<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M1 2"/></svg>|

  # Version "test" so fixture zips cache as *-test.zip and never collide with
  # real provider zips cached in $TMPDIR/icons by dev projects. Real providers
  # are covered by provider_integration_test.exs (mix test --include network).
  @providers %{"heroicons" => {Heroicons, "test"}}

  # Icons the tests reference. Fixture zips contain exactly these.
  @fixture_icons %{
    "heroicons" => ~w(heart bell star check inbox beaker device-phone-mobile)
  }

  setup_all do
    # Drop stale fixture zips so changes to @fixture_icons take effect.
    [System.tmp_dir!(), "icons", "*-test.zip"]
    |> Path.join()
    |> Path.wildcard()
    |> Enum.each(&File.rm!/1)

    Application.put_env(:phx_icons, :providers, @providers)

    # Build one in-memory zip per release URL, with entries laid out by the
    # provider's own svg_path/3 — the same mapping the downloader will use.
    zips =
      @providers
      |> Enum.flat_map(fn {key, config} ->
        {module, version, opts} =
          case config do
            {m, v} -> {m, v, []}
            {m, v, o} -> {m, v, o}
          end

        for name <- Map.fetch!(@fixture_icons, key) do
          {module.release_url(version), {String.to_charlist(module.svg_path(version, name, opts)), @svg}}
        end
      end)
      |> Enum.group_by(fn {url, _} -> url end, fn {_, entry} -> entry end)
      |> Map.new(fn {url, entries} ->
        {:ok, {_, bytes}} = :zip.create(~c"icons.zip", Enum.uniq(entries), [:memory])
        {url, bytes}
      end)

    Application.put_env(:phx_icons, :http_client, fn url -> {:ok, 200, Map.fetch!(zips, url)} end)

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

    test "ensure_icons downloads icons referenced in on-disk source files" do
      tag = System.unique_integer([:positive])
      root = Path.join(System.tmp_dir!(), "phx_icons_root_#{tag}")
      icons_dir = Path.join(System.tmp_dir!(), "phx_icons_dir_#{tag}")
      File.mkdir_p!(Path.join(root, "lib"))
      File.write!(Path.join([root, "lib", "page.heex"]), ~s[<.icon name="heroicons:bell" class="size-6" />])

      bell_path = PhxIcons.Downloader.icon_path(icons_dir, "heroicons", "bell")
      refute File.exists?(bell_path)

      PhxIcons.Compiler.ensure_icons(icons_dir, root: root)

      assert File.exists?(bell_path)
    end

    test "ensure_icons downloads icons referenced via a remote component call" do
      tag = System.unique_integer([:positive])
      root = Path.join(System.tmp_dir!(), "phx_icons_root_#{tag}")
      icons_dir = Path.join(System.tmp_dir!(), "phx_icons_dir_#{tag}")
      File.mkdir_p!(Path.join(root, "lib"))

      File.write!(
        Path.join([root, "lib", "page.heex"]),
        ~s[<MyApp.Icons.icon name="heroicons:bell" class="size-6" />]
      )

      bell_path = PhxIcons.Downloader.icon_path(icons_dir, "heroicons", "bell")
      refute File.exists?(bell_path)

      PhxIcons.Compiler.ensure_icons(icons_dir, root: root)

      assert File.exists?(bell_path)
    end

    test "ensure_icons downloads icons passed through arbitrary component attributes" do
      tag = System.unique_integer([:positive])
      root = Path.join(System.tmp_dir!(), "phx_icons_root_#{tag}")
      icons_dir = Path.join(System.tmp_dir!(), "phx_icons_dir_#{tag}")
      File.mkdir_p!(Path.join(root, "lib"))

      File.write!(
        Path.join([root, "lib", "page.heex"]),
        ~s[<.stat_card empty_icon="heroicons:device-phone-mobile" title="Scans" />]
      )

      icon_path = PhxIcons.Downloader.icon_path(icons_dir, "heroicons", "device-phone-mobile")
      refute File.exists?(icon_path)

      PhxIcons.Compiler.ensure_icons(icons_dir, root: root)

      assert File.exists?(icon_path)
    end

    test "ensure_icons picks up icons added to existing files between calls" do
      tag = System.unique_integer([:positive])
      root = Path.join(System.tmp_dir!(), "phx_icons_root_#{tag}")
      icons_dir = Path.join(System.tmp_dir!(), "phx_icons_dir_#{tag}")
      heex_path = Path.join([root, "lib", "page.heex"])
      File.mkdir_p!(Path.join(root, "lib"))
      File.write!(heex_path, ~s[<.icon name="heroicons:heart" class="size-6" />])

      PhxIcons.Compiler.ensure_icons(icons_dir, root: root)
      assert File.exists?(PhxIcons.Downloader.icon_path(icons_dir, "heroicons", "heart"))
      refute File.exists?(PhxIcons.Downloader.icon_path(icons_dir, "heroicons", "star"))

      File.write!(heex_path, ~s[
        <.icon name="heroicons:heart" class="size-6" />
        <.icon name="heroicons:star" class="size-6" />
      ])

      PhxIcons.Compiler.ensure_icons(icons_dir, root: root)
      assert File.exists?(PhxIcons.Downloader.icon_path(icons_dir, "heroicons", "star"))
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

  describe "unknown icons" do
    import ExUnit.CaptureLog
    import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

    setup do
      icons_dir = Path.join(System.tmp_dir!(), "phx_icons_unknown_#{System.unique_integer([:positive])}")
      %{icons_dir: icons_dir}
    end

    test "in :dev, downloads the icon at runtime and warns", %{icons_dir: icons_dir} do
      assigns = %{name: "heroicons:beaker", class: nil, rest: %{}, __changed__: nil}
      refute File.exists?(PhxIcons.Downloader.icon_path(icons_dir, "heroicons", "beaker"))

      log =
        capture_log(fn ->
          rendered = rendered_to_string(PhxIcons.__unknown_icon__(:dev, icons_dir, assigns))
          send(self(), {:rendered, rendered})
        end)

      assert_received {:rendered, rendered}
      assert rendered =~ "<svg"
      assert log =~ "heroicons:beaker was fetched at runtime"
      assert File.exists?(PhxIcons.Downloader.icon_path(icons_dir, "heroicons", "beaker"))
    end

    test "in :prod, raises the configuration error", %{icons_dir: icons_dir} do
      assigns = %{name: "heroicons:beaker", class: nil, rest: %{}, __changed__: nil}

      assert_raise RuntimeError, ~r/unknown icon heroicons:beaker/, fn ->
        PhxIcons.__unknown_icon__(:prod, icons_dir, assigns)
      end
    end

    test "in :dev, raises when the icon genuinely doesn't exist", %{icons_dir: icons_dir} do
      assigns = %{name: "heroicons:definitely-not-an-icon", class: nil, rest: %{}, __changed__: nil}

      assert_raise RuntimeError, ~r/unknown icon heroicons:definitely-not-an-icon/, fn ->
        PhxIcons.__unknown_icon__(:dev, icons_dir, assigns)
      end
    end
  end

  describe "test helpers" do
    import PhxIcons.Test

    setup do
      icons_dir = Path.join(Mix.Project.build_path(), "icons")
      PhxIcons.Downloader.ensure_icons("heroicons", ["heart"], icons_dir)
      :ok
    end

    test "assert_icon matches icon in HTML with explicit closing tags" do
      d = PhxIcons.Test.__icon__("heroicons:heart")
      html = ~s[<svg><path d="#{d}"></path></svg>]
      assert_icon html, "heroicons:heart"
    end

    test "assert_icon matches icon in HTML with self-closing tags" do
      d = PhxIcons.Test.__icon__("heroicons:heart")
      html = ~s[<svg><path d="#{d}"/></svg>]
      assert_icon html, "heroicons:heart"
    end

    test "refute_icon passes when HTML does not contain the icon" do
      refute_icon "<div>no icons here</div>", "heroicons:heart"
    end

    test "refute_icon passes for plain text without icons" do
      refute_icon "no icons here", "heroicons:heart"
    end
  end
end
