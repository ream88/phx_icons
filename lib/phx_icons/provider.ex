defmodule PhxIcons.Provider do
  @moduledoc """
  Behaviour for icon set providers.

  Implement `release_url/1` to return the URL of a zip archive and
  `svg_path/3` to return the path within that archive for a given icon.
  """

  @callback release_url(version :: String.t()) :: String.t()
  @callback svg_path(version :: String.t(), icon_name :: String.t(), opts :: keyword()) ::
              String.t()
end
