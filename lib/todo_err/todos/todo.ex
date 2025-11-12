defmodule TodoErr.Todos.Todo do
  @moduledoc """
  Schema for a Todo item.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "todos" do
    field :description, :string
    field :completed, :boolean, default: false
    field :blocked, :boolean, default: false
    field :completed_at, :utc_datetime
    field :scheduled_for, :date

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(todo, attrs) do
    todo
    |> cast(attrs, [:description, :completed, :blocked, :completed_at, :scheduled_for])
    |> validate_required([:description])
    |> validate_length(:description, min: 1, max: 1000)
    |> maybe_set_completed_at()
    |> maybe_set_scheduled_for()
  end

  defp maybe_set_completed_at(changeset) do
    completed = get_change(changeset, :completed)
    
    cond do
      completed == true and is_nil(get_field(changeset, :completed_at)) ->
        put_change(changeset, :completed_at, DateTime.utc_now() |> DateTime.truncate(:second))
      
      completed == false ->
        put_change(changeset, :completed_at, nil)
      
      true ->
        changeset
    end
  end

  defp maybe_set_scheduled_for(changeset) do
    if is_nil(get_field(changeset, :scheduled_for)) and is_nil(get_change(changeset, :scheduled_for)) do
      put_change(changeset, :scheduled_for, Date.utc_today())
    else
      changeset
    end
  end
end
