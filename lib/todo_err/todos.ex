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
  then by position (lowest first).

  ## Examples

      iex> list_todos()
      [%Todo{}, ...]

  """
  def list_todos do
    Todo
    |> order_by([t], [asc: t.completed, asc: t.position])
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
    # Get the next position for new todos
    max_position =
      from(t in Todo, select: max(t.position))
      |> Repo.one() || 0

    attrs = Map.put(attrs, :position, max_position + 1)

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

  @doc """
  Reorders todos based on a list of todo IDs in the new order.
  Updates the position field for all affected todos.

  ## Examples

      iex> reorder_todos([3, 1, 2])
      {:ok, [%Todo{}, ...]}

  """
  def reorder_todos(todo_ids) when is_list(todo_ids) do
    Repo.transaction(fn ->
      todo_ids
      |> Enum.with_index()
      |> Enum.map(fn {id, index} ->
        todo = get_todo!(id)
        {:ok, updated_todo} = update_todo(todo, %{position: index + 1})
        updated_todo
      end)
    end)
  end
end
