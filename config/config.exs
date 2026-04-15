import Config

config :phx_icons,
  start_server: config_env() != :prod,
  providers: %{}
