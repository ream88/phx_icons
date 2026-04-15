defmodule PhxIcons.Server do
  @moduledoc false

  use GenServer

  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def fetch!(name) do
    GenServer.call(__MODULE__, {:fetch, name}, 30_000)
  end

  @impl true
  def init(_opts) do
    icons_dir =
      :phx_icons
      |> :code.priv_dir()
      |> to_string()
      |> Path.join("icons")

    {:ok, %{icons_dir: icons_dir, cache: %{}}}
  end

  @impl true
  def handle_call({:fetch, name}, _from, %{cache: cache} = state) do
    case Map.fetch(cache, name) do
      {:ok, svg} ->
        {:reply, svg, state}

      :error ->
        {provider, icon} = parse_name!(name)
        PhxIcons.Downloader.ensure_icons(provider, [icon], state.icons_dir)

        svg_path = PhxIcons.Downloader.icon_path(state.icons_dir, provider, icon)
        svg = PhxIcons.SVG.parse(File.read!(svg_path))

        {:reply, svg, put_in(state.cache[name], svg)}
    end
  end

  defp parse_name!(name) do
    case String.split(name, ":", parts: 2) do
      [provider, icon] -> {provider, icon}
      _ -> raise "PhxIcons: invalid name #{name}. Expected provider:icon-name"
    end
  end
end
