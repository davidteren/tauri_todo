defmodule TodoErrWeb.CoreComponents do
  @moduledoc """
  Provides core UI components for TodoErr.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  @doc """
  Renders a button with Radiant-inspired styling.

  ## Examples

      <.button>Send!</.button>
      <.button variant="secondary" phx-click="go">Send!</.button>
      <.button variant="outline" class="ml-2">Send!</.button>
  """
  attr :type, :string, default: nil
  attr :variant, :string, default: "primary", values: ~w(primary secondary outline)
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        button_variant(@variant),
        "phx-submit-loading:opacity-75",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  defp button_variant("primary") do
    [
      "inline-flex items-center justify-center px-4 py-2",
      "rounded-full border border-transparent bg-gray-950 shadow-md",
      "text-base font-medium whitespace-nowrap text-white",
      "hover:bg-gray-800 active:bg-gray-900",
      "disabled:bg-gray-950 disabled:opacity-40"
    ]
  end

  defp button_variant("secondary") do
    [
      "relative inline-flex items-center justify-center px-4 py-2",
      "rounded-full border border-transparent bg-white/15 shadow-md ring-1 ring-gray-950/15",
      "after:absolute after:inset-0 after:rounded-full after:shadow-[inset_0_0_2px_1px_#ffffff4d]",
      "text-base font-medium whitespace-nowrap text-gray-950",
      "hover:bg-white/20 active:bg-white/25",
      "disabled:bg-white/15 disabled:opacity-40"
    ]
  end

  defp button_variant("outline") do
    [
      "inline-flex items-center justify-center px-3 py-1.5",
      "rounded-lg border border-transparent shadow-sm ring-1 ring-black/10",
      "text-sm font-medium whitespace-nowrap text-gray-950",
      "hover:bg-gray-50 active:bg-gray-100",
      "disabled:bg-transparent disabled:opacity-40"
    ]
  end

  @doc """
  Renders an input with label and error messages.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               range search select tel text textarea time url week)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  slot :inner_block

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(field.errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div phx-feedback-for={@name}>
      <label class="flex items-center gap-4 text-sm leading-2 text-gray-600">
        <input type="hidden" name={@name} value="false" />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class="rounded border-gray-300 text-indigo-600 focus:ring-indigo-600"
          {@rest}
        />
        <%= @label %>
      </label>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <select
        id={@id}
        name={@name}
        class="mt-2 block w-full rounded-md border border-gray-300 bg-white shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
        multiple={@multiple}
        {@rest}
      >
        <option :if={@prompt} value=""><%= @prompt %></option>
        <%= Phoenix.HTML.Form.options_for_select(@options, @value) %>
      </select>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <textarea
        id={@id}
        name={@name}
        class={[
          "mt-2 block w-full rounded-lg text-gray-900 focus:ring-0 sm:text-sm sm:leading-6",
          "min-h-[6rem] phx-no-feedback:border-gray-300 phx-no-feedback:focus:border-indigo-400",
          @errors == [] && "border-gray-300 focus:border-indigo-400",
          @errors != [] && "border-rose-400 focus:border-rose-400"
        ]}
        {@rest}
      ><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[
          "mt-2 block w-full rounded-lg px-3 py-2 text-base text-gray-950",
          "border border-gray-300 shadow-sm ring-1 ring-black/5",
          "placeholder:text-gray-500",
          "focus:outline-none focus:ring-2 focus:ring-gray-950 focus:border-transparent",
          "phx-no-feedback:border-gray-300",
          @errors == [] && "border-gray-300",
          @errors != [] && "border-rose-400 ring-rose-400"
        ]}
        {@rest}
      />
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for} class="block text-sm font-semibold leading-6 text-gray-950">
      <%= render_slot(@inner_block) %>
    </label>
    """
  end

  @doc """
  Renders a large heading with Radiant-inspired typography.

  ## Examples

      <.heading>Close every deal</.heading>
      <.heading class="max-w-3xl">Your custom heading</.heading>
  """
  attr :class, :string, default: nil
  attr :rest, :global

  slot :inner_block, required: true

  def heading(assigns) do
    ~H"""
    <h2
      class={[
        "text-4xl font-medium tracking-tighter text-pretty text-gray-950 sm:text-6xl",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </h2>
    """
  end

  @doc """
  Renders a small subheading with uppercase styling.

  ## Examples

      <.subheading>Sales</.subheading>
  """
  attr :class, :string, default: nil
  attr :rest, :global

  slot :inner_block, required: true

  def subheading(assigns) do
    ~H"""
    <h3
      class={[
        "font-mono text-xs/5 font-semibold tracking-widest text-gray-500 uppercase",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </h3>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="mt-3 flex gap-3 text-sm leading-6 text-rose-600 phx-no-feedback:hidden">
      <.icon name="hero-exclamation-circle-mini" class="mt-0.5 h-5 w-5 flex-none" />
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  @doc """
  Renders a simple icon.
  """
  attr :name, :string, required: true
  attr :class, :string, default: nil

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  @doc """
  Renders flash notices.
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :kind, fn -> :info end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={"flash-#{@kind}"}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("#flash-#{@kind}")}
      role="alert"
      class={[
        "fixed top-2 right-2 mr-2 w-80 sm:w-96 z-50 rounded-lg p-3 ring-1",
        "transition-opacity duration-300",
        @kind == :info && "bg-emerald-50 text-emerald-800 ring-emerald-500 fill-cyan-900",
        @kind == :error && "bg-rose-50 text-rose-900 shadow-md ring-rose-500 fill-rose-900"
      ]}
      {@rest}
    >
      <p :if={@kind == :info} class="flex items-center gap-1.5 text-sm font-semibold leading-6">
        <.icon name="hero-information-circle-mini" class="h-4 w-4" />
        <%= msg %>
      </p>
      <p :if={@kind == :error} class="flex items-center gap-1.5 text-sm font-semibold leading-6">
        <.icon name="hero-exclamation-circle-mini" class="h-4 w-4" />
        <%= msg %>
      </p>
      <button type="button" class="group absolute top-1 right-1 p-2" aria-label="close">
        <.icon name="hero-x-mark-solid" class="h-5 w-5 opacity-40 group-hover:opacity-70" />
      </button>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  def flash_group(assigns) do
    ~H"""
    <.flash kind={:info} flash={@flash} />
    <.flash kind={:error} flash={@flash} />
    """
  end

  defp hide(js, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:translate-x-0", "opacity-0 translate-y-2 sm:translate-x-2"}
    )
  end

  defp translate_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", fn _ -> to_string(value) end)
    end)
  end

  defp translate_error(msg), do: msg
end
