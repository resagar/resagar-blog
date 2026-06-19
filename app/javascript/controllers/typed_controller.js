import { Controller } from "@hotwired/stimulus"

// Typewriter effect: escribe → pausa → borra → siguiente palabra → loop
// Soporta colores por palabra y degradados via CSS (linear-gradient).
export default class extends Controller {
  static values = {
    words: { type: Array, default: [] },
    colors: { type: Array, default: [] },
    typeSpeed: { type: Number, default: 100 },
    deleteSpeed: { type: Number, default: 50 },
    pauseAfterType: { type: Number, default: 2000 },
    pauseAfterDelete: { type: Number, default: 500 }
  }

  connect() {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      this.element.innerHTML = this.wordsValue[0] || ""
      return
    }

    if (this.wordsValue.length === 0) return

    this.wordIndex = 0
    this.charIndex = 0
    this.isDeleting = false
    this.type()
  }

  isGradient(color) {
    return color && (
      color.includes("gradient") ||
      color.includes("linear-") ||
      color.includes("radial-")
    )
  }

  textStyleFor(color) {
    if (!color) return ""
    if (this.isGradient(color)) {
      return `background: ${color}; -webkit-background-clip: text; background-clip: text; color: transparent;`
    }
    return `color: ${color};`
  }

  type() {
    const currentWord = this.wordsValue[this.wordIndex]
    const currentColor = this.colorsValue[this.wordIndex] || this.colorsValue[0] || ""
    const style = this.textStyleFor(currentColor)

    if (this.isDeleting) {
      this.charIndex--
    } else {
      this.charIndex++
    }

    const visible = currentWord.substring(0, this.charIndex)
    const showCaret = !(this.isDeleting && this.charIndex === 0)
    const caretHtml = showCaret ? '<span class="typed-caret">_</span>' : ""

    this.element.innerHTML = `<span class="typed-text" style="${style}">${visible}</span>${caretHtml}`

    let delay = this.isDeleting ? this.deleteSpeedValue : this.typeSpeedValue

    if (!this.isDeleting && this.charIndex === currentWord.length) {
      this.isDeleting = true
      delay = this.pauseAfterTypeValue
    } else if (this.isDeleting && this.charIndex === 0) {
      this.isDeleting = false
      this.wordIndex = (this.wordIndex + 1) % this.wordsValue.length
      delay = this.pauseAfterDeleteValue
    }

    setTimeout(() => this.type(), delay)
  }

  disconnect() {
    this.element.innerHTML = this.wordsValue[0] || ""
  }
}
