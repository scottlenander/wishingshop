import { Controller } from "@hotwired/stimulus"

// Announcements carousel (products/_announcements).
//
// - Auto-advances every `interval` ms, unless the visitor prefers reduced motion.
// - Pauses while hovered or focused, and stays paused after Pause is pressed
//   (WCAG 2.2.2: moving content needs a way to stop it).
// - The live region is quiet while rotating and polite otherwise, so screen
//   readers only announce slides the visitor chose to see.
export default class extends Controller {
  static targets = ["slide", "dot", "pauseButton", "status"]
  static values = { interval: { type: Number, default: 6000 }, index: { type: Number, default: 0 } }

  connect() {
    this.pausedByUser = false
    this.hovering = false
    this.focused = false
    this.reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    if (this.reducedMotion) this.pausedByUser = true
    this.render()
    this.updateTimer()
  }

  disconnect() {
    this.stopTimer()
  }

  next() {
    this.show(this.indexValue + 1)
  }

  previous() {
    this.show(this.indexValue - 1)
  }

  goTo(event) {
    this.show(event.params.index)
  }

  togglePause() {
    this.pausedByUser = !this.pausedByUser
    this.updateTimer()
  }

  hoverStart() { this.hovering = true; this.updateTimer() }
  hoverEnd() { this.hovering = false; this.updateTimer() }
  focusStart() { this.focused = true; this.updateTimer() }
  focusEnd(event) {
    if (this.element.contains(event.relatedTarget)) return
    this.focused = false
    this.updateTimer()
  }

  // Private

  show(index) {
    const count = this.slideTargets.length
    this.indexValue = (index + count) % count
  }

  indexValueChanged() {
    this.render()
  }

  render() {
    this.slideTargets.forEach((slide, i) => { slide.hidden = i !== this.indexValue })
    this.dotTargets.forEach((dot, i) => {
      if (i === this.indexValue) dot.setAttribute("aria-current", "true")
      else dot.removeAttribute("aria-current")
    })
  }

  get rotating() {
    return this.slideTargets.length > 1 && !this.pausedByUser && !this.hovering && !this.focused
  }

  updateTimer() {
    this.stopTimer()
    if (this.rotating) {
      this.timer = setInterval(() => this.next(), this.intervalValue)
    }

    if (this.hasStatusTarget) this.statusTarget.setAttribute("aria-live", this.rotating ? "off" : "polite")
    if (this.hasPauseButtonTarget) {
      const paused = this.pausedByUser
      this.pauseButtonTarget.textContent = paused ? "Play" : "Pause"
      this.pauseButtonTarget.setAttribute("aria-label", paused ? "Play announcements" : "Pause announcements")
    }
  }

  stopTimer() {
    clearInterval(this.timer)
    this.timer = null
  }
}
