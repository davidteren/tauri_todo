// Phoenix LiveView client setup with ES module imports
// Import Phoenix and LiveView JS clients from dependencies (no npm required)
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"

// LiveView Hooks
let Hooks = {}

Hooks.DragDrop = {
  mounted() {
    console.log("DragDrop hook mounted for element:", this.el)
    this.setupDragDrop()
  },

  updated() {
    console.log("DragDrop hook updated")
    this.setupDragDrop()
  },

  destroyed() {
    console.log("DragDrop hook destroyed")
    if (this.dragCleanup) this.dragCleanup()
  },

  setupDragDrop() {
    if (this.dragCleanup) this.dragCleanup()

    const todoContainer =
      this.el.closest("[data-todos-container]") || this.el.parentElement || document.querySelector(".space-y-3")

    if (!todoContainer) {
      console.warn("No todo container found")
      return
    }

    let draggedElement = null
    let placeholder = null

    const createPlaceholder = () => {
      const div = document.createElement("div")
      div.className = "rounded-3xl bg-blue-100/50 border-2 border-dashed border-blue-400 h-20"
      return div
    }

    const listeners = []

    const addListener = (element, event, handler) => {
      if (element) {
        element.addEventListener(event, handler)
        listeners.push({ element, event, handler })
      }
    }

    const removeListeners = () => {
      listeners.forEach(({ element, event, handler }) => {
        element.removeEventListener(event, handler)
      })
      listeners.length = 0
    }

    this.dragCleanup = removeListeners

    const getDragAfterElement = (container, y) => {
      const draggableElements = Array.from(container.querySelectorAll("[data-todo-id]:not(.opacity-50)"))

      return draggableElements.reduce(
        (closest, child) => {
          const box = child.getBoundingClientRect()
          const offset = y - box.top - box.height / 2

          if (offset < 0 && offset > closest.offset) {
            return { offset: offset, element: child }
          } else {
            return closest
          }
        },
        { offset: Number.NEGATIVE_INFINITY }
      ).element
    }

    const dragStartHandler = (e) => {
      console.log("Drag start")
      draggedElement = this.el
      e.dataTransfer.effectAllowed = "move"
      e.dataTransfer.setData("text/html", this.el.outerHTML)

      this.el.classList.add("opacity-50", "scale-95", "shadow-lg")
      placeholder = createPlaceholder()
      document.body.classList.add("dragging")
    }

    const dragEndHandler = (_e) => {
      console.log("Drag end")
      if (draggedElement) {
        draggedElement.classList.remove("opacity-50", "scale-95", "shadow-lg")
      }

      if (placeholder && placeholder.parentNode) {
        placeholder.parentNode.removeChild(placeholder)
      }

      document.body.classList.remove("dragging")
      draggedElement = null
      placeholder = null
    }

    const dragOverHandler = (e) => {
      e.preventDefault()
      e.dataTransfer.dropEffect = "move"

      const afterElement = getDragAfterElement(todoContainer, e.clientY)

      if (afterElement == null) {
        todoContainer.appendChild(placeholder)
      } else {
        todoContainer.insertBefore(placeholder, afterElement)
      }
    }

    const dropHandler = (e) => {
      e.preventDefault()
      console.log("Drop event")

      if (!draggedElement || !placeholder) return

      todoContainer.insertBefore(draggedElement, placeholder)

      const todoElements = Array.from(todoContainer.querySelectorAll("[data-todo-id]"))
      const todoIds = todoElements.map((el) => el.dataset.todoId)

      console.log("Reordering todos:", todoIds)
      this.pushEvent("reorder_todos", { todo_ids: todoIds })
    }

    addListener(this.el, "dragstart", dragStartHandler)
    addListener(this.el, "dragend", dragEndHandler)
    addListener(todoContainer, "dragover", dragOverHandler)
    addListener(todoContainer, "drop", dropHandler)

    const isEditing = this.el.classList.contains("cursor-not-allowed")
    // Set the draggable property reliably
    this.el.draggable = !isEditing
  }
}

// Initialize LiveView
const csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute("content")

// Configure topbar for page loading states
if (typeof topbar !== "undefined") {
  topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
  window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300))
  window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide())
}

const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
})

// Connect if there are any LiveViews on the page
liveSocket.connect()

// Expose for debugging and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)
// The latency simulator is for testing and can be toggled in the dev console:
window.liveSocket = liveSocket
