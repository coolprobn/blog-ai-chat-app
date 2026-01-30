import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.scrollTop = this.element.scrollHeight
  }
}
