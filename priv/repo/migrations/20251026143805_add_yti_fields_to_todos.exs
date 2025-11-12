defmodule TodoErr.Repo.Migrations.AddYtiFieldsToTodos do
  use Ecto.Migration

  def change do
    alter table(:todos) do
      add :blocked, :boolean, default: false, null: false
      add :completed_at, :utc_datetime
      add :scheduled_for, :date
    end
  end
end
