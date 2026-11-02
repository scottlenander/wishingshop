import { Controller } from "@hotwired/stimulus"

// Formats the card expiry as MM/YY while typing: "1" "2" -> "12/", then "12/30".
// A first digit above 1 becomes a month ("4" -> "04/"). Deleting works normally:
// the slash isn't added back while removing characters.
export default class extends Controller {
  format(event) {
    const deleting = event.inputType?.startsWith("delete")
    let digits = this.element.value.replace(/\D/g, "").slice(0, 4)

    if (!deleting && digits.length === 1 && digits > "1") digits = `0${digits}`

    if (digits.length > 2) {
      this.element.value = `${digits.slice(0, 2)}/${digits.slice(2)}`
    } else if (digits.length === 2 && !deleting) {
      this.element.value = `${digits}/`
    } else {
      this.element.value = digits
    }
  }
}
