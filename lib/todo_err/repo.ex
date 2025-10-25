defmodule TodoErr.Repo do
  use Ecto.Repo,
    otp_app: :todo_err,
    adapter: Ecto.Adapters.SQLite3
end
