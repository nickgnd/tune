# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.41",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :dart_sass,
  version: "1.49.11",
  default: [
    args: ~w(css/app.scss ../priv/static/assets/app.css),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures the endpoint
config :tune, TuneWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "e2NnkG7ooENrurt7RUM9EtxWsHaMoRZRd/zSSJ4/PiikAuYhsipmPM+hrnufoeBZ",
  render_errors: [view: TuneWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Tune.PubSub,
  live_view: [signing_salt: "Op07Dt9x"]

config :tune,
  spotify_session: Tune.Spotify.Session.HTTP,
  spotify_client: Tune.Spotify.Client.HTTP

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

spotify_scope =
  ~w(
    streaming
    user-modify-playback-state
    user-read-currently-playing
    user-read-email
    user-read-playback-state
    user-read-private
    user-read-recently-played
    user-top-read
  )
  |> Enum.join(",")

config :ueberauth, Ueberauth,
  providers: [
    spotify: {Ueberauth.Strategy.Spotify, [default_scope: spotify_scope]}
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
