defmodule TuneWeb.FullPlayerComponent do
  @moduledoc false

  use TuneWeb, :live_component

  alias TuneWeb.{PlayerView, ProgressBarComponent}

  @default_small_thumbnail "https://via.placeholder.com/48"

  alias Tune.Spotify.Schema.{Episode, Track}

  @spec thumbnail(Track.t() | Episode.t()) :: String.t()
  defp thumbnail(%Track{album: album}),
    do: Map.get(album.thumbnails, :large, @default_small_thumbnail)

  defp thumbnail(%Episode{thumbnails: thumbnails}),
    do: Map.get(thumbnails, :large, @default_small_thumbnail)

  @spec name(Track.t() | Episode.t()) :: String.t()
  defp name(%Episode{name: name}), do: name
  defp name(%Track{name: name}), do: name
end
