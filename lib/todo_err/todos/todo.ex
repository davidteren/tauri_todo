defmodule TodoErr.Todos.Todo do
  @moduledoc """
  Schema for a Todo item.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "todos" do
    field :description, :string
    field :completed, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(todo, attrs) do
    todo
    |> cast(attrs, [:description, :completed])
    |> validate_required([:description])
    |> validate_length(:description, min: 1, max: 500)
  end
end
