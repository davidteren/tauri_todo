// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

// Drag and Drop Hook
let Hooks = {}

Hooks.DragDrop = {
  mounted() {
    this.setupDragDrop()
  },

  setupDragDrop() {
    const todoContainer = this.el.closest('[data-todos-container]') || 
                         this.el.parentElement || 
                         document.querySelector('.space-y-3')
    
    if (!todoContainer) return

    let draggedElement = null
    let placeholder = null

    // Create placeholder element
    const createPlaceholder = () => {
      const div = document.createElement('div')
      div.className = 'rounded-3xl bg-blue-100/50 border-2 border-dashed border-blue-400 h-20'
      return div
    }

    // Handle drag start
    this.el.addEventListener('dragstart', (e) => {
      draggedElement = this.el
      e.dataTransfer.effectAllowed = 'move'
      e.dataTransfer.setData('text/html', this.el.outerHTML)
      
      // Add dragging styles
      this.el.classList.add('opacity-50', 'scale-95', 'shadow-lg')
      
      // Create placeholder
      placeholder = createPlaceholder()
      
      // Add visual feedback
      document.body.classList.add('dragging')
    })

    // Handle drag end
    this.el.addEventListener('dragend', (e) => {
      if (draggedElement) {
        draggedElement.classList.remove('opacity-50', 'scale-95', 'shadow-lg')
      }
      
      // Remove placeholder
      if (placeholder && placeholder.parentNode) {
        placeholder.parentNode.removeChild(placeholder)
      }
      
      // Remove visual feedback
      document.body.classList.remove('dragging')
      
      draggedElement = null
      placeholder = null
    })

    // Handle drag over
    todoContainer.addEventListener('dragover', (e) => {
      e.preventDefault()
      e.dataTransfer.dropEffect = 'move'
      
      const afterElement = getDragAfterElement(todoContainer, e.clientY)
      
      if (afterElement == null) {
        todoContainer.appendChild(placeholder)
      } else {
        todoContainer.insertBefore(placeholder, afterElement)
      }
    })

    // Handle drop
    todoContainer.addEventListener('drop', (e) => {
      e.preventDefault()
      
      if (!draggedElement || !placeholder) return

      // Insert the dragged element before the placeholder
      todoContainer.insertBefore(draggedElement, placeholder)
      
      // Get all todo IDs in new order
      const todoElements = Array.from(todoContainer.querySelectorAll('[data-todo-id]'))
      const todoIds = todoElements.map(el => el.dataset.todoId)
      
      // Send reorder event to LiveView
      this.pushEvent('reorder_todos', { todo_ids: todoIds })
    })

    // Helper function to find drop target
    function getDragAfterElement(container, y) {
      const draggableElements = Array.from(container.querySelectorAll('[data-todo-id]:not(.opacity-50)'))
      
      return draggableElements.reduce((closest, child) => {
        const box = child.getBoundingClientRect()
        const offset = y - box.top - box.height / 2
        
        if (offset < 0 && offset > closest.offset) {
          return { offset: offset, element: child }
        } else {
          return closest
        }
      }, { offset: Number.NEGATIVE_INFINITY }).element
    }

    // Make element draggable
    this.el.setAttribute('draggable', 'true')
  }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: Hooks
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket
