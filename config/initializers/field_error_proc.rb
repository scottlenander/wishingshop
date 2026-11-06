# Rails wraps a form field that has an error in <div class="field_with_errors">.
# Same wrapper and class as Rails' default (styles rely on it), plus a test id
# so Playwright can find the marked fields (e2e/pageObjects/checkoutPage.ts).
ActionView::Base.field_error_proc = proc do |html_tag, _instance|
  ActionController::Base.helpers.tag.div(html_tag, class: "field_with_errors", data: { testid: "field-error" })
end
