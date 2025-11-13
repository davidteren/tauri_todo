defmodule TodoErr.Repo.Migrations.AddPositionToTodos do
  use Ecto.Migration

  def change do
    alter table(:todos) do
      add :position, :integer, default: 0, null: false, if_not_exists: true
    end

    create_if_not_exists index(:todos, [:position])
  end
end
