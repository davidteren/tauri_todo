defmodule TodoErr.Repo.Migrations.CreateTodos do
  use Ecto.Migration

  def change do
    create table(:todos) do
      add :description, :text, null: false
      add :completed, :boolean, default: false, null: false

      timestamps(type: :utc_datetime)
    end

    # Index for efficient querying by completion status
    create index(:todos, [:completed])
    # Index for sorting by insertion time
    create index(:todos, [:inserted_at])
  end
end
