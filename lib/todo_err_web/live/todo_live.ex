defmodule TodoErrWeb.TodoLive do
  use TodoErrWeb, :live_view

  alias TodoErr.Todos

  @impl true
  def mount(_params, _session, socket) do
    todos = Todos.list_todos()

    socket =
      socket
      |> assign(:todos, todos)
      |> assign(:grouped_todos, group_todos_by_yti(todos))
      |> assign(:form, to_form(%{"description" => ""}))
      |> assign(:editing_id, nil)
      |> assign(:show_completed, false)
      |> assign(:expanded_id, nil)

    {:ok, socket}
  end

  @impl true
  def handle_event("add_todo", %{"description" => description}, socket) do
    # Trim each line individually while preserving newlines
    trimmed_description =
      description
      |> String.split("\n")
      |> Enum.map(&String.trim/1)
      |> Enum.join("\n")
      |> String.trim()

    case Todos.create_todo(%{description: trimmed_description}) do
      {:ok, _todo} ->
        socket =
          socket
          |> refresh_todos()
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
        socket =
          socket
          |> refresh_todos()
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
        socket =
          socket
          |> refresh_todos()
          |> put_flash(:info, "Todo deleted successfully!")

        {:noreply, socket}

      {:error, _changeset} ->
        socket =
          socket
          |> put_flash(:error, "Failed to delete todo")

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("toggle_blocked", %{"id" => id}, socket) do
    todo = Todos.get_todo!(id)

    case Todos.update_todo(todo, %{blocked: !todo.blocked}) do
      {:ok, _todo} ->
        socket =
          socket
          |> refresh_todos()
          |> clear_flash()

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update todo")}
    end
  end

  @impl true
  def handle_event("start_edit", %{"id" => id}, socket) do
    {:noreply, assign(socket, :editing_id, String.to_integer(id))}
  end

  @impl true
  def handle_event("cancel_edit", _params, socket) do
    {:noreply, assign(socket, :editing_id, nil)}
  end

  @impl true
  def handle_event("toggle_expand", %{"id" => id}, socket) do
    id = String.to_integer(id)
    expanded_id = if socket.assigns.expanded_id == id, do: nil, else: id
    {:noreply, assign(socket, :expanded_id, expanded_id)}
  end

  @impl true
  def handle_event("toggle_show_completed", _params, socket) do
    {:noreply, assign(socket, :show_completed, !socket.assigns.show_completed)}
  end

  @impl true
  def handle_event("save_edit", %{"id" => id, "description" => description}, socket) do
    todo = Todos.get_todo!(id)

    # Trim each line individually while preserving newlines
    trimmed_description =
      description
      |> String.split("\n")
      |> Enum.map(&String.trim/1)
      |> Enum.join("\n")
      |> String.trim()

    case Todos.update_todo(todo, %{description: trimmed_description}) do
      {:ok, _todo} ->
        socket =
          socket
          |> refresh_todos()
          |> assign(:editing_id, nil)
          |> clear_flash()

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update todo")}
    end
  end

  defp group_todos_by_yti(todos) do
    today = Date.utc_today()
    yesterday = Date.add(today, -1)

    todos
    |> Enum.group_by(fn todo ->
      cond do
        todo.blocked -> :impediments
        todo.completed and todo.completed_at &&
          Date.compare(DateTime.to_date(todo.completed_at), yesterday) == :eq -> :yesterday
        todo.completed -> :completed
        true -> :today
      end
    end)
    |> Map.put_new(:today, [])
    |> Map.put_new(:impediments, [])
    |> Map.put_new(:yesterday, [])
    |> Map.put_new(:completed, [])
  end

  defp refresh_todos(socket) do
    todos = Todos.list_todos()

    socket
    |> assign(:todos, todos)
    |> assign(:grouped_todos, group_todos_by_yti(todos))
  end

  @impl true
  def handle_event("reorder_todos", %{"todo_ids" => ids}, socket) do
    case Todos.reorder_todos(ids) do
      {:ok, _} ->
        {:noreply, refresh_todos(socket)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to reorder todos")}
    end
  end

  defp render_todo_card(assigns, todo) do
    assigns = assign(assigns, :todo, todo)

    ~H"""
    <div
      id={"todo-#{@todo.id}"}
      class={[
        "group rounded-3xl bg-gradient-to-br from-yellow-50/80 via-pink-50/80 to-purple-100/80 backdrop-blur-sm shadow-sm ring-1 ring-black/5 hover:shadow-md transition-all duration-200",
        if(@editing_id == @todo.id, do: "", else: "cursor-grab active:cursor-grabbing")
      ]}
      data-todo-id={@todo.id}
      data-hover-delay="600"
      data-hover-expanded="false"
      phx-hook="DragDrop"
    >
      <div class="flex items-center gap-4 p-5">
        <!-- Drag Handle -->
        <div class={[
          "flex-shrink-0 text-gray-400 hover:text-gray-600",
          if(@editing_id == @todo.id, do: "cursor-not-allowed opacity-50", else: "cursor-grab active:cursor-grabbing")
        ]}>
          <.icon name="hero-bars-3" class="w-5 h-5" />
        </div>

        <!-- Checkbox -->
        <button
          phx-click="toggle_complete"
          phx-value-id={@todo.id}
          class={[
            "flex-shrink-0 w-5 h-5 rounded border-2 transition-all flex items-center justify-center",
            if(@todo.completed,
              do: "bg-gray-950 border-gray-950",
              else: "border-gray-400 hover:border-gray-950"
            )
          ]}
        >
          <%= if @todo.completed do %>
            <.icon name="hero-check" class="w-3.5 h-3.5 text-white" />
          <% end %>
        </button>

        <!-- Todo Text / Edit Field -->
        <div class="flex-1 min-w-0">
          <%= if @editing_id == @todo.id do %>
            <div class="space-y-2">
              <form phx-submit="save_edit" phx-value-id={@todo.id} class="flex gap-2">
                <textarea
                  id={"todo-#{@todo.id}-editor"}
                  name="description"
                  rows="4"
                  class="flex-1 px-3 py-2 text-base font-medium text-gray-950 bg-white/60 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 resize-none font-mono text-sm"
                  placeholder="Enter Markdown content..."
                  phx-hook="MarkdownEditor"
                ><%= @todo.description %></textarea>
                <div class="flex flex-col gap-1">
                  <button type="submit" class="p-2 text-green-600 hover:bg-green-50 rounded-lg" title="Save">
                    <.icon name="hero-check" class="w-5 h-5" />
                  </button>
                  <button type="button" phx-click="cancel_edit" class="p-2 text-gray-400 hover:bg-gray-100 rounded-lg" title="Cancel">
                    <.icon name="hero-x-mark" class="w-5 h-5" />
                  </button>
                </div>
              </form>
            </div>
          <% else %>
            <% title = @todo.description |> String.split("\n") |> Enum.at(0, "") |> String.trim() %>
            <div class="space-y-1">
              <button
                type="button"
                phx-click="toggle_expand"
                phx-value-id={@todo.id}
                class={[
                  "w-full text-left text-base font-medium transition-all overflow-hidden whitespace-nowrap text-ellipsis",
                  if(@todo.completed, do: "line-through text-gray-400", else: "text-gray-950"),
                  if(@expanded_id == @todo.id, do: "hidden", else: "block hover-hide")
                ]}
                title={title}
              >
                <%= title %>
              </button>
              <div id={"todo-#{@todo.id}-markdown"} class={["markdown-content", if(@expanded_id == @todo.id, do: "block", else: "hidden hover-reveal-block")]} phx-hook="MarkdownRenderer">
                <p class={[
                  "text-base font-medium transition-all whitespace-pre-wrap",
                  if(@todo.completed,
                    do: "line-through text-gray-400",
                    else: "text-gray-950"
                  )
                ]}><%= @todo.description %></p>
              </div>
            </div>
          <% end %>
        </div>

        <!-- Action Buttons -->
        <div class="flex items-center gap-1">
          <!-- Block/Unblock Button -->
          <button
            phx-click="toggle_blocked"
            phx-value-id={@todo.id}
            class={[
              "flex-shrink-0 p-2 rounded-lg transition-all",
              if(@todo.blocked,
                do: "text-red-600 bg-red-50",
                else: "text-gray-400 hover:text-orange-600 hover:bg-orange-50 opacity-0 group-hover:opacity-100"
              )
            ]}
            title={if @todo.blocked, do: "Unblock", else: "Mark as blocked"}
          >
            <.icon name="hero-exclamation-triangle" class="w-5 h-5" />
          </button>

          <!-- Delete Button -->
          <button
            phx-click="delete_todo"
            phx-value-id={@todo.id}
            class="flex-shrink-0 p-2 text-gray-400 hover:text-rose-600 hover:bg-rose-50 rounded-lg transition-all opacity-0 group-hover:opacity-100"
            title="Delete todo"
          >
            <.icon name="hero-trash" class="w-5 h-5" />
          </button>
        </div>
      </div>
    </div>
    """
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
