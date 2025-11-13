// Phoenix LiveView client setup with ES module imports
// Import Phoenix and LiveView JS clients from dependencies (no npm required)
import { Socket } from "phoenix"
import "phoenix_html"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"

// Markdown support
let Hooks = {}

// Markdown Editor Hook
Hooks.MarkdownEditor = {
  mounted() {
    this.setupEditor()
  },

  stripMarkdownTitle(text) {
    if (!text) return ''
    // Remove blockquote and leading hashes
    let t = text
      .replace(/^\s*>\s*/, '')
      .replace(/^\s*#+\s*/, '')
    // Replace image with its alt text
    t = t.replace(/!\[[^\]]*\]\(([^)]+)\)/g, (m) => {
      const m2 = m.match(/!\[([^\]]*)\]/)
      return m2 && m2[1] ? m2[1] : ''
    })
    // Links -> text
    t = t.replace(/\[([^\]]+)\]\(([^)]+)\)/g, '$1')
    // Inline code -> plain
    t = t.replace(/`([^`]+)`/g, '$1')
    // Bold / italic variants
    t = t.replace(/\*\*([^*]+)\*\*/g, '$1')
    t = t.replace(/\*([^*]+)\*/g, '$1')
    t = t.replace(/__([^_]+)__/g, '$1')
    t = t.replace(/_([^_]+)_/g, '$1')
    return t.trim()
  },

  updated() {
    this.setupEditor()
  },

  destroyed() {
    if (this.editor) {
      this.editor.toTextArea()
      this.editor = null
    }
    if (this._resizeHandler && this.textarea) {
      this.textarea.removeEventListener('input', this._resizeHandler)
    }
  },

  setupEditor() {
    // Simple textarea for now, can be enhanced with EasyMDE
    const textarea = this.el.querySelector('textarea[name="description"]')
    if (!textarea) return

    // Add markdown support styling
    textarea.classList.add('markdown-editor')

    // Auto-resize to fit content
    const autosize = (ta) => {
      ta.style.height = 'auto'
      ta.style.overflow = 'hidden'
      ta.style.height = ta.scrollHeight + 'px'
    }

    // Save references for cleanup
    if (this._resizeHandler && this.textarea) {
      this.textarea.removeEventListener('input', this._resizeHandler);
    }
    this.textarea = textarea;
    this._resizeHandler = () => autosize(textarea);
    // Initialize and bind
    autosize(textarea);
    this.textarea.addEventListener('input', this._resizeHandler);
  }
}

// Markdown Renderer Hook
Hooks.MarkdownRenderer = {
  mounted() {
    this.render()
  },

  updated() {
    this.render()
  },

  render() {
    const p = this.el.querySelector('p')
    const raw = this.el.dataset.raw || (p ? p.textContent : this.el.textContent) || ''
    const safe = this.escapeHTML(raw)

    const lines = safe.split('\n')
    const first = (lines.shift() || '').trim()
    const title = this.stripMarkdownTitle(first)
    const body = lines.join('\n')
    const bodyHtml = this.parseMarkdown(body)
    const headerHtml = title ? `<h1>${title}</h1>` : ''
    this.el.innerHTML = headerHtml + bodyHtml
  },

  escapeHTML(text) {
    return text
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;')
  },

  stripMarkdownTitle(text) {
    if (!text) return ''
    let t = text
      .replace(/^\s*>\s*/, '')
      .replace(/^\s*#+\s*/, '')
    t = t.replace(/!\[[^\]]*\]\(([^)]+)\)/g, (m) => {
      const m2 = m.match(/!\[([^\]]*)\]/)
      return m2 && m2[1] ? m2[1] : ''
    })
    t = t.replace(/\[([^\]]+)\]\(([^)]+)\)/g, '$1')
    t = t.replace(/`([^`]+)`/g, '$1')
    t = t.replace(/\*\*([^*]+)\*\*/g, '$1')
    t = t.replace(/\*([^*]+)\*/g, '$1')
    t = t.replace(/__([^_]+)__/g, '$1')
    t = t.replace(/_([^_]+)_/g, '$1')
    return t.trim()
  },

  parseMarkdown(text) {
    // Minimal Markdown support; input already escaped
    let out = text
      .replace(/^######\s+(.*)$/gim, '<h6>$1</h6>')
      .replace(/^#####\s+(.*)$/gim, '<h5>$1</h5>')
      .replace(/^####\s+(.*)$/gim, '<h4>$1</h4>')
      .replace(/^###\s+(.*)$/gim, '<h3>$1</h3>')
      .replace(/^##\s+(.*)$/gim, '<h2>$1</h2>')
      .replace(/^#\s+(.*)$/gim, '<h1>$1</h1>')
      .replace(/\*\*(.+?)\*\*/gim, '<strong>$1</strong>')
      .replace(/\*(.+?)\*/gim, '<em>$1</em>')
      .replace(/`([^`]+?)`/gim, '<code>$1</code>')
      .replace(/\[([^\]]+)\]\(([^)]+)\)/gim, '<a href="$2" target="_blank" rel="noopener noreferrer" class="text-blue-600 hover:underline">$1</a>')

    // Lists: convert lines starting with - or * into <li>, then wrap contiguous blocks into <ul>
    out = out.replace(/^(?:\s*[-*]\s+.+(?:\n|$))+?/gim, (block) => {
      const items = block
        .trimEnd()
        .split(/\n/)
        .map((line) => line.replace(/^\s*[-*]\s+(.+)$/, '<li>$1</li>'))
        .join('')
      return `<ul>${items}</ul>`
    })

    // Paragraph breaks
    out = out.replace(/\n\n+/g, '<br>')
    return out
  }
}

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
    let hoverTimer = null

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

    const setHoverExpanded = (expanded) => {
      if (expanded) {
        this.el.setAttribute('data-hover-expanded', 'true')
      } else {
        this.el.setAttribute('data-hover-expanded', 'false')
      }
    }

    this.dragCleanup = () => {
      removeListeners()
      if (hoverTimer) {
        clearTimeout(hoverTimer)
        hoverTimer = null
      }
      setHoverExpanded(false)
    }

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
      if (hoverTimer) { clearTimeout(hoverTimer); hoverTimer = null }
      setHoverExpanded(false)
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

    // Delayed hover expansion
    const hoverDelay = parseInt(this.el.getAttribute('data-hover-delay') || '600', 10)
    // initialize collapsed
    setHoverExpanded(false)
    const pointerEnterHandler = () => {
      if (hoverTimer) clearTimeout(hoverTimer)
      hoverTimer = setTimeout(() => setHoverExpanded(true), isNaN(hoverDelay) ? 600 : hoverDelay)
    }
    const pointerLeaveHandler = () => {
      if (hoverTimer) {
        clearTimeout(hoverTimer)
        hoverTimer = null
      }
      setHoverExpanded(false)
    }

    addListener(this.el, "pointerenter", pointerEnterHandler)
    addListener(this.el, "pointerleave", pointerLeaveHandler)

    // Edit mode activation helpers
    const isInteractiveTarget = (target) => !!(target && target.closest('button, a, input, textarea, [contenteditable]'))
    const startEdit = () => {
      const id = this.el.dataset.todoId
      if (id) this.pushEvent("start_edit", { id })
    }

    // Double click to edit (desktop)
    const dblClickHandler = (e) => {
      if (isInteractiveTarget(e.target)) return
      startEdit()
    }

    // Long press to edit (mobile/desktop)
    let pressTimer = null
    let pressStart = { x: 0, y: 0 }
    const PRESS_DELAY = 500
    const MOVE_TOLERANCE = 6

    const pointerDownHandler = (e) => {
      if (isInteractiveTarget(e.target)) return
      pressStart = { x: e.clientX ?? 0, y: e.clientY ?? 0 }
      clearTimeout(pressTimer)
      pressTimer = setTimeout(() => {
        pressTimer = null
        startEdit()
      }, PRESS_DELAY)
    }

    const pointerMoveHandler = (e) => {
      if (!pressTimer) return
      const dx = Math.abs((e.clientX ?? 0) - pressStart.x)
      const dy = Math.abs((e.clientY ?? 0) - pressStart.y)
      if (dx > MOVE_TOLERANCE || dy > MOVE_TOLERANCE) {
        clearTimeout(pressTimer)
        pressTimer = null
      }
    }

    const cancelPress = () => {
      if (pressTimer) {
        clearTimeout(pressTimer)
        pressTimer = null
      }
    }

    addListener(this.el, "dblclick", dblClickHandler)
    addListener(this.el, "pointerdown", pointerDownHandler)
    addListener(this.el, "pointerup", cancelPress)
    addListener(this.el, "pointercancel", cancelPress)
    addListener(this.el, "pointerleave", cancelPress)
    addListener(this.el, "pointermove", pointerMoveHandler)

    addListener(this.el, "dragstart", dragStartHandler)
    addListener(this.el, "dragend", dragEndHandler)
    addListener(todoContainer, "dragover", dragOverHandler)
    addListener(todoContainer, "drop", dropHandler)

    const isEditing = !this.el.classList.contains("cursor-grab")
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
