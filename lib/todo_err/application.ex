defmodule TodoErr.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # For desktop app: ensure database directory exists before starting repo
    if Application.get_env(:todo_err, :env) == :prod do
      ensure_database_directory()
    end

    run_migrations()

    children = [
      TodoErrWeb.Telemetry,
      TodoErr.Repo,
      {DNSCluster, query: Application.get_env(:todo_err, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: TodoErr.PubSub},
      # Start to serve requests, typically the last entry
      TodoErrWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TodoErr.Supervisor]

    # Run migrations after supervisor starts
    case Supervisor.start_link(children, opts) do
      {:ok, pid} ->
        run_migrations()
        {:ok, pid}

      error ->
        error
    end
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TodoErrWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp ensure_database_directory do
    # Get the database path from repo config
    database_path = TodoErr.Repo.config()[:database]

    if database_path do
      database_dir = Path.dirname(database_path)
      File.mkdir_p!(database_dir)
    end
  end

  defp run_migrations do
    # Run migrations automatically on startup
    # This is critical for desktop apps where users don't have mix available
    repos = Application.fetch_env!(:todo_err, :ecto_repos)

    for repo <- repos do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end

    :ok
  end
end
