import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :tune, TuneWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "aaaaaaaa",
  server: false

config :tune,
  spotify_session: Tune.Spotify.Session.Mock,
  spotify_client: Tune.Spotify.Client.Mock

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

config :stream_data,
  max_runs: if(System.get_env("CI"), do: 20, else: 10)
