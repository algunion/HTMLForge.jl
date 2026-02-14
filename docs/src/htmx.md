# HTMX Support

HTMLForge treats [HTMX](https://htmx.org/) as a first-class citizen. All HTMX attribute helpers mutate the element **in place** and return it, enabling chaining. Attributes are stored with the `data-hx-` prefix for HTML spec compliance.

!!! tip "Looking for the experimental DSL?"
    Check out the [Experimental HTMX](@ref) page for the macro-powered `@hx` and pipe `hx.*` interfaces.

## Generic Attribute Setter

`hxattr!(el, attr, value)` — Set any htmx attribute. The `data-hx-` prefix is added automatically:

```julia
el = HTMLElement(:div)
hxattr!(el, "custom", "value")   # → data-hx-custom="value"
hxattr!(el, :target, "#result")  # → data-hx-target="#result"
```

## AJAX Request Helpers

| Function                      | htmx attribute     |
| ----------------------------- | ------------------ |
| `hxget!(el, url)`             | `data-hx-get`      |
| `hxpost!(el, url)`            | `data-hx-post`     |
| `hxput!(el, url)`             | `data-hx-put`      |
| `hxpatch!(el, url)`           | `data-hx-patch`    |
| `hxdelete!(el, url)`          | `data-hx-delete`   |
| `hxrequest!(el, method, url)` | `data-hx-<method>` |

```julia
el = HTMLElement(:button)
hxget!(el, "/api/items")
hxpost!(el, "/api/submit")
hxrequest!(el, :put, "/api/update")
```

## Trigger

`hxtrigger!(el, event; once, changed, delay, throttle, from, target, consume, queue, filter)`

Build complex `hx-trigger` values with full modifier support:

```julia
el = HTMLElement(:div)
hxtrigger!(el, "click"; once=true, delay="500ms")
# → data-hx-trigger="click once delay:500ms"

hxtrigger!(el, "keyup"; changed=true, delay="500ms")
# → data-hx-trigger="keyup changed delay:500ms"

hxtrigger!(el, "click"; filter="ctrlKey")
# → data-hx-trigger="click[ctrlKey]"
```

## Target and Swap

- `hxtarget!(el, selector)` — CSS selector, `"this"`, `"closest ..."`, etc.
- `hxswap!(el, style; ...)` — swap style with optional modifiers
- `hxswapoob!(el, value)` — out-of-band swap
- `hxselect!(el, selector)` — select subset of response
- `hxselectoob!(el, selectors)` — out-of-band select

`hxswap!` supports keyword modifiers: `transition`, `swap`, `settle`, `ignoreTitle`, `scroll`, `show`, `focusScroll`.

Valid swap styles: `"innerHTML"`, `"outerHTML"`, `"afterbegin"`, `"beforebegin"`, `"beforeend"`, `"afterend"`, `"delete"`, `"none"`.

```julia
el = HTMLElement(:div)
hxswap!(el, "innerHTML"; transition=true, settle="100ms")
# → data-hx-swap="innerHTML transition:true settle:100ms"
```

## Values and URLs

- `hxvals!(el, json)` — include additional values (JSON string)
- `hxpushurl!(el, value)` — push URL to browser history (`"true"`, `"false"`, or URL)
- `hxreplaceurl!(el, value)` — replace URL without history entry

## User Interaction

- `hxconfirm!(el, message)` — show `confirm()` dialog before request
- `hxprompt!(el, message)` — show `prompt()` dialog before request
- `hxindicator!(el, selector)` — element to show during request

## Progressive Enhancement and Parameters

- `hxboost!(el, value)` — progressively enhance links/forms (`"true"/"false"`)
- `hxinclude!(el, selector)` — include values of other elements
- `hxparams!(el, value)` — filter request parameters (`"*"`, `"none"`, list, `"not ..."`)
- `hxheaders!(el, json)` — additional request headers (JSON string)
- `hxsync!(el, value)` — synchronize requests (`"closest form:abort"`, `"this:drop"`, etc.)
- `hxencoding!(el, encoding)` — request encoding (default: `"multipart/form-data"`)
- `hxext!(el, extensions)` — enable htmx extensions (comma-separated)

## Event Handling

`hxon!(el, event, script)` — inline event handler via `data-hx-on:<event>`:

```julia
hxon!(el, "click", "alert('clicked!')")
# → data-hx-on:click="alert('clicked!')"
```

## Disabling and Inheritance

- `hxdisable!(el)` — disable htmx processing on element and children
- `hxdisabledelt!(el, selector)` — disable elements during request
- `hxdisinherit!(el, attrs)` — disable attribute inheritance (`"*"` or space-separated list)
- `hxinherit!(el, attrs)` — enable attribute inheritance

## History and Preservation

- `hxhistory!(el, value)` — control history caching (`"false"` to prevent)
- `hxhistoryelt!(el)` — mark as history snapshot source
- `hxpreserve!(el)` — keep element unchanged between requests (needs stable `id`)

## Request Configuration and Validation

- `hxrequestconfig!(el, value)` — configure request (`"timeout:3000, credentials:true"`)
- `hxvalidate!(el)` — enable HTML5 validation before request

## Chaining Example

All htmx helpers return the element, so they can be chained:

```julia
el = HTMLElement(:button)
el |> x -> hxpost!(x, "/submit") |>
     x -> hxtarget!(x, "#result") |>
     x -> hxswap!(x, "outerHTML") |>
     x -> hxconfirm!(x, "Are you sure?")
```

!!! note
    For a much more ergonomic chaining experience, see the [Experimental HTMX](@ref) pipe DSL.
