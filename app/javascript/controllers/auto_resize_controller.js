import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { minRows: { type: Number, default: 1 }, maxRows: { type: Number, default: 12 } }

  connect() {
    this.resize()
  }

  resize() {
    const el = this.element
    el.style.height = "auto"
    const lineHeight = parseInt(getComputedStyle(el).lineHeight, 10) || 24
    const rows = Math.min(this.maxRowsValue, Math.max(this.minRowsValue, Math.floor(el.scrollHeight / lineHeight)))
    el.style.height = `${rows * lineHeight}px`
  }
}
