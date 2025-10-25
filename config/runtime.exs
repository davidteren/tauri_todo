import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/todo_err start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :todo_err, TodoErrWeb.Endpoint, server: true
end

if config_env() == :prod do
  # Desktop application configuration
  # Database path should be set by Tauri launcher to ~/Library/Application Support/TodoErr/
  database_path =
    System.get_env("DATABASE_PATH") ||
      raise """
      environment variable DATABASE_PATH is missing.
      For desktop app, this should be set by the Tauri launcher.
      Example: ~/Library/Application Support/TodoErr/todo_err.db
      """

  config :todo_err, TodoErr.Repo,
    database: database_path,
    # Small pool size for SQLite to avoid SQLITE_BUSY errors
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "5")

  # For desktop apps, we generate a secret key base if not provided
  # This is acceptable since the app runs locally and doesn't need
  # to maintain session consistency across multiple servers
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      :crypto.strong_rand_bytes(64) |> Base.encode64(padding: false) |> binary_part(0, 64)

  # Desktop app configuration: localhost only, dynamic port
  # Port 0 means the OS will assign an available port dynamically
  # The Tauri launcher will discover this port from stdout
  port = String.to_integer(System.get_env("PORT") || "0")

  config :todo_err, :dns_cluster_query, nil

  config :todo_err, TodoErrWeb.Endpoint,
    # Desktop app runs on localhost only
    url: [host: "localhost", port: port],
    http: [
      # Bind to localhost only (127.0.0.1) for security
      # This prevents external network access to the app
      ip: {127, 0, 0, 1},
      port: port
    ],
    secret_key_base: secret_key_base,
    # Enable server for desktop app
    server: true

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :todo_err, TodoErrWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :todo_err, TodoErrWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.
end
