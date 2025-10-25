defmodule TodoErrWeb.TodoLive do
  use TodoErrWeb, :live_view

  alias TodoErr.Todos

  @impl true
  def mount(_params, _session, socket) do
    todos = Todos.list_todos()

    socket =
      socket
      |> assign(:todos, todos)
      |> assign(:form, to_form(%{"description" => ""}))

    {:ok, socket}
  end

  @impl true
  def handle_event("add_todo", %{"description" => description}, socket) do
    case Todos.create_todo(%{description: description}) do
      {:ok, _todo} ->
        todos = Todos.list_todos()

        socket =
          socket
          |> assign(:todos, todos)
          |> assign(:form, to_form(%{"description" => ""}))
          |> put_flash(:info, "Todo added successfully!")

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        socket =
          socket
          |> put_flash(:error, "Failed to add todo: #{format_errors(changeset)}")

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("toggle_complete", %{"id" => id}, socket) do
    todo = Todos.get_todo!(id)

    case Todos.toggle_complete(todo) do
      {:ok, _todo} ->
        todos = Todos.list_todos()

        socket =
          socket
          |> assign(:todos, todos)
          |> clear_flash()

        {:noreply, socket}

      {:error, _changeset} ->
        socket =
          socket
          |> put_flash(:error, "Failed to update todo")

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("delete_todo", %{"id" => id}, socket) do
    todo = Todos.get_todo!(id)

    case Todos.delete_todo(todo) do
      {:ok, _todo} ->
        todos = Todos.list_todos()

        socket =
          socket
          |> assign(:todos, todos)
          |> put_flash(:info, "Todo deleted successfully!")

        {:noreply, socket}

      {:error, _changeset} ->
        socket =
          socket
          |> put_flash(:error, "Failed to delete todo")

        {:noreply, socket}
    end
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
    |> Enum.map(fn {field, errors} -> "#{field}: #{Enum.join(errors, ", ")}" end)
    |> Enum.join("; ")
  end
end
