# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     TodoErr.Repo.insert!(%TodoErr.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias TodoErr.Repo
alias TodoErr.Todos.Todo

count = Repo.aggregate(Todo, :count, :id)

if count == 0 do
  today = Date.utc_today()
  yesterday = Date.add(today, -1)
  now = DateTime.utc_now() |> DateTime.truncate(:second)
  y_noon =
    NaiveDateTime.new!(yesterday, ~T[12:00:00])
    |> DateTime.from_naive!("Etc/UTC")

  base_pos = Repo.aggregate(Todo, :max, :position) || 0

  seeds = [
    %{description: "Rename app to TaskFlow", completed: true, completed_at: now},
    %{description: "Design a compact header for desktop", completed: true, completed_at: y_noon},
    %{
      description: "# Mark \"Completed Yesterday\"\n\n- Add context function\n- LiveView event and button\n- Verify grouping shows item under Yesterday",
      completed: false
    },
    %{
      description: "Investigate drag/drop reorder glitch when dropping at end of list",
      blocked: true
    },
    %{
      description: "Implement Markdown renderer sanitization and styling\n\n- Escape HTML\n- Support headings, lists, links, code"
    },
    %{
      description: "Refactor Todos context for clarity: list, reorder, toggle",
      completed: true,
      completed_at: y_noon
    },
    %{
      description: "Add seed data for demo and testing",
      completed: false
    },
    %{
      description: "# Tauri integration\n\nEnsure sidecar starts Phoenix release and navigates when server is ready.",
      completed: false
    },
    %{
      description: "Polish button hover and focus states using Tailwind transitions"
    },
    %{
      description: "Write README section on development workflow"
    },
    %{
      description: "Audit icons and replace with <.icon> component usages",
      completed: true,
      completed_at: y_noon
    },
    %{
      description: "Add small badge with version and build date in footer"
    }
  ]

  seeds
  |> Enum.with_index()
  |> Enum.each(fn {attrs, idx} ->
    attrs = Map.put(attrs, :position, base_pos + idx + 1)
    %Todo{} |> Todo.changeset(attrs) |> Repo.insert!()
  end)
end
