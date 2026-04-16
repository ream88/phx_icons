defmodule PhxIcons.Provider do
  @moduledoc """
  Behaviour for icon set providers.
  """

  @callback release_url(version :: String.t()) :: String.t()
  @callback svg_path(version :: String.t(), icon_name :: String.t(), opts :: keyword()) ::
              String.t()
end
