defmodule PhxIcons.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children =
      if Application.get_env(:phx_icons, :start_server, false) do
        [PhxIcons.Server]
      else
        []
      end

    Supervisor.start_link(children, strategy: :one_for_one, name: PhxIcons.Supervisor)
  end
end
