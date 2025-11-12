defmodule TodoErr.Todos do
  @moduledoc """
  The Todos context.
  Provides functions for managing todo items.
  """

  import Ecto.Query, warn: false
  alias TodoErr.Repo
  alias TodoErr.Todos.Todo

  @doc """
  Returns the list of todos, sorted with incomplete tasks first,
  then by creation date (newest first).

  ## Examples

      iex> list_todos()
      [%Todo{}, ...]

  """
  def list_todos do
    Todo
    |> order_by([t], [asc: t.completed, desc: t.inserted_at])
    |> Repo.all()
  end

  @doc """
  Creates a todo.

  ## Examples

      iex> create_todo(%{description: "Buy milk"})
      {:ok, %Todo{}}

      iex> create_todo(%{description: ""})
      {:error, %Ecto.Changeset{}}

  """
  def create_todo(attrs \\ %{}) do
    %Todo{}
    |> Todo.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Toggles the completed status of a todo.

  ## Examples

      iex> toggle_complete(todo)
      {:ok, %Todo{}}

      iex> toggle_complete(invalid_todo)
      {:error, %Ecto.Changeset{}}

  """
  def toggle_complete(%Todo{} = todo) do
    todo
    |> Todo.changeset(%{completed: !todo.completed})
    |> Repo.update()
  end

  @doc """
  Deletes a todo.

  ## Examples

      iex> delete_todo(todo)
      {:ok, %Todo{}}

      iex> delete_todo(invalid_todo)
      {:error, %Ecto.Changeset{}}

  """
  def delete_todo(%Todo{} = todo) do
    Repo.delete(todo)
  end

  @doc """
  Gets a single todo.

  Raises `Ecto.NoResultsError` if the Todo does not exist.

  ## Examples

      iex> get_todo!(123)
      %Todo{}

      iex> get_todo!(456)
      ** (Ecto.NoResultsError)

  """
  def get_todo!(id), do: Repo.get!(Todo, id)

  @doc """
  Updates a todo.

  ## Examples

      iex> update_todo(todo, %{description: "New description"})
      {:ok, %Todo{}}

      iex> update_todo(todo, %{description: ""})
      {:error, %Ecto.Changeset{}}

  """
  def update_todo(%Todo{} = todo, attrs) do
    todo
    |> Todo.changeset(attrs)
    |> Repo.update()
  end
end
