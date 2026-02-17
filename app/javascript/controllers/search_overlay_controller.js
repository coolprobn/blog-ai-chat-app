import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "input", "panel", "result", "loading", "error", "submitBtn", "backdrop"]

  connect() {
    this.closeOnEscape = this.closeOnEscape.bind(this)
  }

  submit(e) {
    e.preventDefault()
    const q = this.inputTarget.value.trim()
    if (!q) return

    this.showLoading()
    this.hideError()
    this.showPanel()

    const body = new FormData()
    body.append("q", q)
    const csrf = document.querySelector('meta[name="csrf-token"]')?.getAttribute("content")
    if (csrf) body.append("authenticity_token", csrf)

    fetch(this.formTarget.action || "/search", {
      method: "POST",
      body,
      headers: { "Accept": "application/json", "X-Requested-With": "XMLHttpRequest" }
    })
      .then((res) => res.json())
      .then((data) => {
        if (data.error) {
          this.showError(data.error)
          this.showPlaceholder()
          return
        }
        this.showResult(data)
      })
      .catch(() => {
        this.showError("Search failed. Please try again.")
        this.showPlaceholder()
      })
      .finally(() => this.hideLoading())
  }

  showResult(data) {
    let html = `<div class="search-answer prose prose-sm max-w-none text-gray-700 [&_a]:text-[#00638a] [&_a]:underline">${data.answer_html || escapeHtml(data.answer || "")}</div>`
    if (data.sources && data.sources.length > 0) {
      html += `<div class="mt-4 border-t border-gray-200 pt-3"><p class="text-xs font-semibold uppercase tracking-wider text-gray-400 mb-2">Sources</p><ul class="space-y-1">`
      data.sources.forEach((s) => {
        const title = escapeHtml(s.title || s.url || "")
        const url = s.url ? escapeHtml(s.url) : "#"
        html += `<li><a href="${url}" target="_blank" rel="noopener" class="text-sm text-[#00638a] hover:underline">${title}</a></li>`
      })
      html += `</ul></div>`
    }
    this.resultTarget.innerHTML = html
    this.resultTarget.classList.remove("hidden")
  }

  showPlaceholder() {
    this.resultTarget.innerHTML = '<p class="text-sm text-gray-500">Type a question and press Enter to search.</p>'
    this.resultTarget.classList.remove("hidden")
  }

  showLoading() {
    if (this.hasLoadingTarget) this.loadingTarget.classList.remove("hidden")
    if (this.hasResultTarget) this.resultTarget.classList.add("hidden")
  }

  hideLoading() {
    if (this.hasLoadingTarget) this.loadingTarget.classList.add("hidden")
  }

  showError(msg) {
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = msg
      this.errorTarget.classList.remove("hidden")
    }
  }

  hideError() {
    if (this.hasErrorTarget) {
      this.errorTarget.classList.add("hidden")
    }
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

function escapeHtml(str) {
  const div = document.createElement("div")
  div.textContent = str
  return div.innerHTML
}
