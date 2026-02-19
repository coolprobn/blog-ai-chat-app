import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "input", "panel", "result", "loading", "error", "submitBtn", "backdrop"]

  connect() {
    this.closeOnEscape = this.closeOnEscape.bind(this)
  }

  onSubmitStart() {
    this.showPanel()
    // Use getElementById so we target current DOM nodes (Turbo Stream replace can leave targets stale)
    const loadingEl = document.getElementById("search-loading")
    const resultEl = document.getElementById("search-result")
    const errorEl = document.getElementById("search-error")
    if (errorEl) errorEl.classList.add("hidden")
    if (resultEl) resultEl.classList.add("hidden")
    if (loadingEl) loadingEl.classList.remove("hidden")
  }

  onSubmitEnd() {
    const loadingEl = document.getElementById("search-loading")
    const resultEl = document.getElementById("search-result")
    if (loadingEl) loadingEl.classList.add("hidden")
    if (resultEl) resultEl.classList.remove("hidden")
  }

  showPanel() {
    this.panelTarget.classList.remove("hidden")
    if (this.hasBackdropTarget) this.backdropTarget.classList.remove("hidden")
    document.addEventListener("keydown", this.closeOnEscape)
  }

  close() {
    this.panelTarget.classList.add("hidden")
    if (this.hasBackdropTarget) this.backdropTarget.classList.add("hidden")
    document.removeEventListener("keydown", this.closeOnEscape)
  }

  keepOpen(e) {
    e.stopPropagation()
  }

  closeOnEscape(e) {
    if (e.key === "Escape") this.close()
  }
}
