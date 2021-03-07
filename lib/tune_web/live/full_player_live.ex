defmodule TuneWeb.FullPlayerLive do
  @moduledoc """
  TBD
  """

  use TuneWeb, :live_view

  alias Tune.Spotify.Schema.{Album, Device, Player, Track, User}

  alias TuneWeb.{
    AlbumView,
    ArtistView,
    MiniPlayerComponent,
    FullPlayerComponent,
    PaginationView,
    ProgressBarComponent,
    SearchView,
    ShowView,
    SuggestionsView
  }

  @default_time_range "short_term"

  @initial_state [
    type: :track,
    user: nil,
    now_playing: %Player{},
    item: :not_fetched,
  ]

  @impl true
  def mount(_params, session, socket) do
    case Tune.Auth.load_user(session) do
      {:authenticated, session_id, user} ->
        now_playing = spotify_session().now_playing(session_id)
        devices = spotify_session().get_devices(session_id)

        socket =
          case spotify_session().get_player_token(session_id) do
            {:ok, token} ->
              assign(socket, :player_token, token)

            error ->
              handle_spotify_session_result(error, socket)
          end

        if connected?(socket) do
          spotify_session().subscribe(session_id)
        end

        {:ok,
         socket
         |> assign(@initial_state)
         |> assign(:static_changed, static_changed?(socket))
         |> assign_new(:player_id, &generate_player_id/0)
         |> assign(
           session_id: session_id,
           user: user,
           premium?: User.premium?(user),
           now_playing: now_playing,
           devices: devices
         )}

      _error ->
        {:ok, redirect(socket, to: "/auth/logout")}
    end
  end

  @impl true
  def handle_event("toggle_play_pause", %{"key" => " "}, socket) do
    spotify_session().toggle_play(socket.assigns.session_id)

    {:noreply, socket}
  end

  def handle_event("toggle_play_pause", %{"key" => _}, socket) do
    {:noreply, socket}
  end

  def handle_event("toggle_play_pause", _params, socket) do
    socket.assigns.session_id
    |> spotify_session().toggle_play()
    |> handle_spotify_session_result(socket)
  end

  def handle_event("play", %{"uri" => uri, "context-uri" => context_uri}, socket) do
    socket.assigns.session_id
    |> spotify_session().play(uri, context_uri)
    |> handle_spotify_session_result(socket)
  end

  def handle_event("play", %{"uri" => uri}, socket) do
    socket.assigns.session_id
    |> spotify_session().play(uri)
    |> handle_spotify_session_result(socket)
  end

  def handle_event("next", _params, socket) do
    socket.assigns.session_id
    |> spotify_session().next()
    |> handle_spotify_session_result(socket)
  end

  def handle_event("prev", _params, socket) do
    socket.assigns.session_id
    |> spotify_session().prev()
    |> handle_spotify_session_result(socket)
  end

  def handle_event("seek", %{"position_ms" => position_ms}, socket) do
    socket.assigns.session_id
    |> spotify_session().seek(position_ms)
    |> handle_spotify_session_result(socket)
  end

  def handle_event("search", params, socket) do
    q = Map.get(params, "q")
    type = Map.get(params, "type", "track")

    {:noreply, push_patch(socket, to: Routes.explorer_path(socket, :search, q: q, type: type))}
  end

  def handle_event("transfer_playback", %{"device" => device_id}, socket) do
    case spotify_session().transfer_playback(socket.assigns.session_id, device_id) do
      :ok ->
        {:noreply, socket}

      error ->
        handle_spotify_session_result(error, socket)
    end
  end

  def handle_event("inc_volume", %{}, socket) do
    case socket.assigns.now_playing.device do
      nil ->
        {:noreply, socket}

      device ->
        volume_percent = min(device.volume_percent + 10, 100)
        set_volume(volume_percent, socket)
    end
  end

  def handle_event("dec_volume", %{}, socket) do
    case socket.assigns.now_playing.device do
      nil ->
        {:noreply, socket}

      device ->
        volume_percent = max(device.volume_percent - 10, 0)
        set_volume(volume_percent, socket)
    end
  end

  def handle_event("set_volume", %{"volume_percent" => volume_percent}, socket) do
    set_volume(volume_percent, socket)
  end

  def handle_event("refresh_devices", _params, socket) do
    :ok = spotify_session().refresh_devices(socket.assigns.session_id)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:now_playing, player}, socket) do
    changes = Player.changes(socket.assigns.now_playing, player)

    cond do
      changes == [] ->
        {:noreply, socket}

      [:progress_ms] == changes ->
        send_update(ProgressBarComponent, id: :progress_bar, progress_ms: player.progress_ms)
        {:noreply, socket}

      :item in changes ->
        case spotify_session().recently_played_tracks(socket.assigns.session_id, limit: 50) do
          {:ok, recently_played_tracks} ->
            {:noreply,
             assign(socket,
               suggestions_recently_played_albums: Album.from_tracks(recently_played_tracks),
               now_playing: player
             )}

          error ->
            handle_spotify_session_result(error, socket)
        end

      true ->
        {:noreply, assign(socket, :now_playing, player)}
    end
  end

  def handle_info({:player_token, token}, socket) do
    {:noreply, assign(socket, :player_token, token)}
  end

  def handle_info({:devices, devices}, socket) do
    {:noreply, assign(socket, :devices, devices)}
  end

  defp spotify_session, do: Application.get_env(:tune, :spotify_session)

  defp handle_spotify_session_result(:ok, socket), do: {:noreply, socket}

  defp handle_spotify_session_result({:error, 404}, socket) do
    {:noreply, put_flash(socket, :error, gettext("No available devices"))}
  end

  defp handle_spotify_session_result({:error, reason}, socket) do
    error_message = gettext("Spotify error: %{reason}", %{reason: inspect(reason)})
    {:noreply, put_flash(socket, :error, error_message)}
  end

  defp set_volume(volume_percent, socket) do
    case spotify_session().set_volume(socket.assigns.session_id, volume_percent) do
      :ok ->
        {:noreply, socket}

      error ->
        handle_spotify_session_result(error, socket)
    end
  end

  defp generate_player_id do
    "tune-" <> Device.generate_name()
  end
end
