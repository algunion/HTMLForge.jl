const HXPREFIX = "data-hx-"
const ALTERNATIVE_HXPREFIX = "hx-"

function ensurehxprefix(attr::Union{AbstractString, Symbol})
    attr_str = string(attr)
    startswith(attr_str, HXPREFIX) && return attr_str
    startswith(attr_str, ALTERNATIVE_HXPREFIX) &&
        return replace(attr_str, ALTERNATIVE_HXPREFIX => HXPREFIX)
    return HXPREFIX * attr_str
end

# ──────────────────────────────────────────────
# Generic htmx attribute setter
# ──────────────────────────────────────────────

"""
    hxattr!(el::HTMLElement, attr::Union{AbstractString,Symbol}, value::AbstractString) -> HTMLElement

Set an arbitrary htmx attribute on an `HTMLElement` in place.
The `data-hx-` prefix is added automatically.
"""
function hxattr!(
        el::HTMLElement, attr::Union{AbstractString, Symbol}, value::AbstractString)
    el[ensurehxprefix(attr)] = value
    return el
end

# ──────────────────────────────────────────────
# Core AJAX request attributes (hx-get/post/put/patch/delete)
# ──────────────────────────────────────────────

"""
    hxrequest!(el::HTMLElement, method::Symbol, url::AbstractString) -> HTMLElement

Add an htmx request attribute to an `HTMLElement` in place and return the modified element.

Valid methods are `:get`, `:post`, `:put`, `:patch`, and `:delete`.
"""
function hxrequest!(
        el::HTMLElement, method::Union{Symbol, AbstractString}, url::AbstractString)
    method = lowercase(string(method)) |> ensurehxprefix
    el[method] = url
    return el
end

"""
    hxget!(el::HTMLElement, url::AbstractString) -> HTMLElement

Add an `hx-get` attribute to an `HTMLElement` in place and return the modified element.
"""
hxget!(el::HTMLElement, url::AbstractString) = hxrequest!(el, :get, url)

"""
    hxpost!(el::HTMLElement, url::AbstractString) -> HTMLElement

Add an `hx-post` attribute to an `HTMLElement` in place and return the modified element.
"""
hxpost!(el::HTMLElement, url::AbstractString) = hxrequest!(el, :post, url)

"""
    hxput!(el::HTMLElement, url::AbstractString) -> HTMLElement

Add an `hx-put` attribute to an `HTMLElement` in place and return the modified element.
"""
hxput!(el::HTMLElement, url::AbstractString) = hxrequest!(el, :put, url)

"""
    hxpatch!(el::HTMLElement, url::AbstractString) -> HTMLElement

Add an `hx-patch` attribute to an `HTMLElement` in place and return the modified element.
"""
hxpatch!(el::HTMLElement, url::AbstractString) = hxrequest!(el, :patch, url)

"""
    hxdelete!(el::HTMLElement, url::AbstractString) -> HTMLElement

Add an `hx-delete` attribute to an `HTMLElement` in place and return the modified element.
"""
hxdelete!(el::HTMLElement, url::AbstractString) = hxrequest!(el, :delete, url)

# ──────────────────────────────────────────────
# hx-trigger
# ──────────────────────────────────────────────

"""
    hxtrigger!(el::HTMLElement, event::AbstractString; kwargs...) -> HTMLElement

Add an `hx-trigger` attribute to an `HTMLElement` with appropriate modifiers and return the modified element.

# Arguments
- `el`: The HTML element to add the trigger to
- `event`: The event name (e.g., "click", "mouseenter", "load", "revealed")
- `once::Bool`: Whether the trigger should only fire once
- `changed::Bool`: Whether the trigger should only fire if the value of the element has changed
- `delay::AbstractString`: A time interval (e.g., "1s") to wait before issuing the request
- `throttle::AbstractString`: A time interval (e.g., "1s") to throttle requests
- `from::AbstractString`: A CSS selector to listen for the event on a different element
- `target::AbstractString`: A CSS selector to filter the trigger to elements matching the selector
- `consume::Bool`: Whether the event should be consumed (not propagated to parent elements)
- `queue::AbstractString`: Queue strategy when a request is in flight ("first", "last", "all", "none")
- `filter::AbstractString`: A JavaScript expression to filter when the trigger fires (without brackets)
"""
function hxtrigger!(el::HTMLElement, event::AbstractString;
        once::Bool = false, changed::Bool = false,
        delay::Union{Nothing, AbstractString} = nothing,
        throttle::Union{Nothing, AbstractString} = nothing,
        from::Union{Nothing, AbstractString} = nothing,
        target::Union{Nothing, AbstractString} = nothing,
        consume::Bool = false,
        queue::Union{Nothing, AbstractString} = nothing,
        filter::Union{Nothing, AbstractString} = nothing)

    # Start with the event name
    trigger_value = event

    # Add filter if provided (e.g., "click[ctrlKey]")
    if !isnothing(filter)
        trigger_value = "$trigger_value[$filter]"
    end

    # Add modifiers
    modifiers = String[]
    once && push!(modifiers, "once")
    changed && push!(modifiers, "changed")
    !isnothing(delay) && push!(modifiers, "delay:$delay")
    !isnothing(throttle) && push!(modifiers, "throttle:$throttle")
    !isnothing(from) && push!(modifiers, "from:$from")
    !isnothing(target) && push!(modifiers, "target:$target")
    consume && push!(modifiers, "consume")
    !isnothing(queue) && push!(modifiers, "queue:$queue")

    # Combine event with modifiers
    if !isempty(modifiers)
        trigger_value = "$trigger_value $(join(modifiers, " "))"
    end

    # Add the trigger attribute to the element
    el[ensurehxprefix("trigger")] = trigger_value
    return el
end

"""
    load_trigger(el::HTMLElement; delay::Union{Nothing,AbstractString}=nothing) -> HTMLElement

Add a 'load' trigger to an element, optionally with a delay.

# Examples
```julia
# Trigger on load
load_trigger(el)

# Trigger on load with delay
load_trigger(el; delay="1s")
```
"""
load_trigger(el::HTMLElement; delay::Union{Nothing, AbstractString} = nothing) = hxtrigger!(
    el, "load"; delay = delay)

"""
    revealed_trigger(el::HTMLElement; once::Bool=true) -> HTMLElement

Add a 'revealed' trigger to an element (fires when element scrolls into view).
By default, this only triggers once.
"""
revealed_trigger(el::HTMLElement; once::Bool = true) = hxtrigger!(
    el, "revealed"; once = once)

"""
    intersect_trigger(el::HTMLElement; 
                     root::Union{Nothing,AbstractString}=nothing,
                     threshold::Union{Nothing,Real}=nothing,
                     once::Bool=true) -> HTMLElement

Add an 'intersect' trigger to an element (fires when element intersects the viewport).

# Arguments
- `root`: A CSS selector of the root element for intersection
- `threshold`: A floating point between 0.0 and 1.0 indicating the amount of intersection needed
"""
function intersect_trigger(el::HTMLElement;
        root::Union{Nothing, AbstractString} = nothing,
        threshold::Union{Nothing, Real} = nothing,
        once::Bool = true)

    # Build the event with options
    event = "intersect"
    options = String[]

    !isnothing(root) && push!(options, "root:$root")
    if !isnothing(threshold)
        # Ensure threshold is between 0 and 1
        t = clamp(Float64(threshold), 0.0, 1.0)
        push!(options, "threshold:$t")
    end

    if !isempty(options)
        event = "$event[$(join(options, " "))]"
    end

    hxtrigger!(el, event; once = once)
end

"""
    poll_trigger(el::HTMLElement, interval::AbstractString) -> HTMLElement

Add a polling trigger to an element.

# Arguments
- `interval`: The polling interval (e.g., "2s", "500ms")

# Examples
```julia
# Poll every 2 seconds
poll_trigger(el, "2s")
```
"""
poll_trigger(el::HTMLElement, interval::AbstractString) = hxtrigger!(el, "every $interval")

# ──────────────────────────────────────────────
# hx-target
# ──────────────────────────────────────────────

"""
    hxtarget!(el::HTMLElement, selector::AbstractString) -> HTMLElement

Add an `hx-target` attribute to an `HTMLElement`.

Supported values include standard CSS selectors as well as htmx extended selectors:
`"this"`, `"closest <selector>"`, `"find <selector>"`, `"next <selector>"`, `"previous <selector>"`.
"""
hxtarget!(el::HTMLElement, selector::AbstractString) = hxattr!(el, "target", selector)

# ──────────────────────────────────────────────
# hx-swap
# ──────────────────────────────────────────────

"""
    VALID_SWAP_STYLES

The set of valid swap styles for `hx-swap`.
"""
const VALID_SWAP_STYLES = Set([
    "innerHTML", "outerHTML",
    "afterbegin", "beforebegin",
    "beforeend", "afterend",
    "delete", "none"
])

"""
    hxswap!(el::HTMLElement, style::AbstractString;
            transition::Union{Nothing,Bool}=nothing,
            swap::Union{Nothing,AbstractString}=nothing,
            settle::Union{Nothing,AbstractString}=nothing,
            ignoreTitle::Union{Nothing,Bool}=nothing,
            scroll::Union{Nothing,AbstractString}=nothing,
            show::Union{Nothing,AbstractString}=nothing,
            focusScroll::Union{Nothing,Bool}=nothing) -> HTMLElement

Add an `hx-swap` attribute to an `HTMLElement` with optional modifiers.

# Arguments
- `style`: The swap style — one of "innerHTML" (default), "outerHTML", "afterbegin",
  "beforebegin", "beforeend", "afterend", "delete", "none".
- `transition`: Whether to use the View Transition API for this swap.
- `swap`: A swap delay (e.g. "100ms") between clearing old content and inserting new.
- `settle`: A settle delay (e.g. "100ms") between inserting new content and settling it.
- `ignoreTitle`: If `true`, any `<title>` found in new content will be ignored.
- `scroll`: `"top"` or `"bottom"` — scroll the target element to its top or bottom.
- `show`: `"top"` or `"bottom"` — scroll the target element's top or bottom into view.
- `focusScroll`: Whether the focused element should be scrolled into view.
"""
function hxswap!(el::HTMLElement, style::AbstractString;
        transition::Union{Nothing, Bool} = nothing,
        swap::Union{Nothing, AbstractString} = nothing,
        settle::Union{Nothing, AbstractString} = nothing,
        ignoreTitle::Union{Nothing, Bool} = nothing,
        scroll::Union{Nothing, AbstractString} = nothing,
        show::Union{Nothing, AbstractString} = nothing,
        focusScroll::Union{Nothing, Bool} = nothing)
    style in VALID_SWAP_STYLES ||
        throw(ArgumentError("Invalid swap style: \"$style\". Must be one of: $(join(sort(collect(VALID_SWAP_STYLES)), ", "))"))

    parts = [style]
    !isnothing(transition) && push!(parts, "transition:$(lowercase(string(transition)))")
    !isnothing(swap) && push!(parts, "swap:$swap")
    !isnothing(settle) && push!(parts, "settle:$settle")
    !isnothing(ignoreTitle) && push!(parts, "ignoreTitle:$(lowercase(string(ignoreTitle)))")
    !isnothing(scroll) && push!(parts, "scroll:$scroll")
    !isnothing(show) && push!(parts, "show:$show")
    !isnothing(focusScroll) &&
        push!(parts, "focus-scroll:$(lowercase(string(focusScroll)))")

    el[ensurehxprefix("swap")] = join(parts, " ")
    return el
end

# ──────────────────────────────────────────────
# hx-swap-oob
# ──────────────────────────────────────────────

"""
    hxswapoob!(el::HTMLElement, value::AbstractString="true") -> HTMLElement

Add an `hx-swap-oob` attribute to mark an element for out-of-band swapping.

The `value` can be `"true"` or any valid swap style optionally followed by a CSS selector
(e.g., `"innerHTML:#target"`).
"""
hxswapoob!(el::HTMLElement, value::AbstractString = "true") = hxattr!(el, "swap-oob", value)

# ──────────────────────────────────────────────
# hx-select / hx-select-oob
# ──────────────────────────────────────────────

"""
    hxselect!(el::HTMLElement, selector::AbstractString) -> HTMLElement

Add an `hx-select` attribute to select a subset of the response HTML to swap into the target.
"""
hxselect!(el::HTMLElement, selector::AbstractString) = hxattr!(el, "select", selector)

"""
    hxselectoob!(el::HTMLElement, selectors::AbstractString) -> HTMLElement

Add an `hx-select-oob` attribute to pick out content for out-of-band swaps.

`selectors` is a comma-separated list of element IDs (e.g., `"#info-details,#other-elt"`).
"""
hxselectoob!(el::HTMLElement, selectors::AbstractString) = hxattr!(
    el, "select-oob", selectors)

# ──────────────────────────────────────────────
# hx-vals
# ──────────────────────────────────────────────

"""
    hxvals!(el::HTMLElement, json::AbstractString) -> HTMLElement

Add an `hx-vals` attribute to include additional values with the request.

`json` should be a JSON-formatted string of name-value pairs,
e.g., `\"{"myVal": "My Value"}\"`.
"""
hxvals!(el::HTMLElement, json::AbstractString) = hxattr!(el, "vals", json)

# ──────────────────────────────────────────────
# hx-push-url / hx-replace-url
# ──────────────────────────────────────────────

"""
    hxpushurl!(el::HTMLElement, value::AbstractString="true") -> HTMLElement

Add an `hx-push-url` attribute to push the request URL into the browser location bar,
creating a history entry. Pass `"true"`, `"false"`, or a specific URL.
"""
hxpushurl!(el::HTMLElement, value::AbstractString = "true") = hxattr!(el, "push-url", value)

"""
    hxreplaceurl!(el::HTMLElement, value::AbstractString="true") -> HTMLElement

Add an `hx-replace-url` attribute to replace the current URL in the browser location bar
without creating a new history entry. Pass `"true"`, `"false"`, or a specific URL.
"""
hxreplaceurl!(el::HTMLElement, value::AbstractString = "true") = hxattr!(
    el, "replace-url", value)

# ──────────────────────────────────────────────
# hx-confirm / hx-prompt
# ──────────────────────────────────────────────

"""
    hxconfirm!(el::HTMLElement, message::AbstractString) -> HTMLElement

Add an `hx-confirm` attribute that shows a `confirm()` dialog before issuing the request.
"""
hxconfirm!(el::HTMLElement, message::AbstractString) = hxattr!(el, "confirm", message)

"""
    hxprompt!(el::HTMLElement, message::AbstractString) -> HTMLElement

Add an `hx-prompt` attribute that shows a `prompt()` dialog before submitting the request.
The user's response is included in the request via the `HX-Prompt` header.
"""
hxprompt!(el::HTMLElement, message::AbstractString) = hxattr!(el, "prompt", message)

# ──────────────────────────────────────────────
# hx-indicator
# ──────────────────────────────────────────────

"""
    hxindicator!(el::HTMLElement, selector::AbstractString) -> HTMLElement

Add an `hx-indicator` attribute specifying which element receives the `htmx-request` class
during a request (to show a loading indicator).
"""
hxindicator!(el::HTMLElement, selector::AbstractString) = hxattr!(el, "indicator", selector)

# ──────────────────────────────────────────────
# hx-boost
# ──────────────────────────────────────────────

"""
    hxboost!(el::HTMLElement, value::AbstractString="true") -> HTMLElement

Add an `hx-boost` attribute to progressively enhance links and forms to use AJAX.
"""
hxboost!(el::HTMLElement, value::AbstractString = "true") = hxattr!(el, "boost", value)

# ──────────────────────────────────────────────
# hx-include / hx-params
# ──────────────────────────────────────────────

"""
    hxinclude!(el::HTMLElement, selector::AbstractString) -> HTMLElement

Add an `hx-include` attribute to include values of other elements in the request.

`selector` is a CSS selector indicating the elements whose values should be included.
"""
hxinclude!(el::HTMLElement, selector::AbstractString) = hxattr!(el, "include", selector)

"""
    hxparams!(el::HTMLElement, value::AbstractString) -> HTMLElement

Add an `hx-params` attribute to filter the parameters submitted with a request.

Supported values: `"*"` (all), `"none"`, a comma-separated list of param names,
or `"not <param-list>"` to exclude specific params.
"""
hxparams!(el::HTMLElement, value::AbstractString) = hxattr!(el, "params", value)

# ──────────────────────────────────────────────
# hx-headers
# ──────────────────────────────────────────────

"""
    hxheaders!(el::HTMLElement, json::AbstractString) -> HTMLElement

Add an `hx-headers` attribute to include additional headers with the request.

`json` should be a JSON-formatted string, e.g., `\"{"X-CSRF-Token": "abc123"}\"`.
"""
hxheaders!(el::HTMLElement, json::AbstractString) = hxattr!(el, "headers", json)

# ──────────────────────────────────────────────
# hx-sync
# ──────────────────────────────────────────────

"""
    hxsync!(el::HTMLElement, value::AbstractString) -> HTMLElement

Add an `hx-sync` attribute to control how requests made by different elements are synchronized.

Common values: `"closest form:abort"`, `"this:drop"`, `"this:queue first"`, `"this:queue last"`,
`"this:queue all"`, `"this:replace"`.
"""
hxsync!(el::HTMLElement, value::AbstractString) = hxattr!(el, "sync", value)

# ──────────────────────────────────────────────
# hx-encoding
# ──────────────────────────────────────────────

"""
    hxencoding!(el::HTMLElement, encoding::AbstractString="multipart/form-data") -> HTMLElement

Add an `hx-encoding` attribute to change the request encoding type.

Set to `"multipart/form-data"` for file uploads.
"""
hxencoding!(el::HTMLElement, encoding::AbstractString = "multipart/form-data") = hxattr!(
    el, "encoding", encoding)

# ──────────────────────────────────────────────
# hx-ext
# ──────────────────────────────────────────────

"""
    hxext!(el::HTMLElement, extensions::AbstractString) -> HTMLElement

Add an `hx-ext` attribute to enable htmx extensions for this element and its children.

Multiple extensions can be comma-separated (e.g., `"response-targets,head-support"`).
Use `"ignore:<ext-name>"` to disable an inherited extension.
"""
hxext!(el::HTMLElement, extensions::AbstractString) = hxattr!(el, "ext", extensions)

# ──────────────────────────────────────────────
# hx-on
# ──────────────────────────────────────────────

"""
    hxon!(el::HTMLElement, event::AbstractString, script::AbstractString) -> HTMLElement

Add an `hx-on:<event>` attribute to handle events with inline scripts.

The event name supports both htmx events (e.g., `"htmx:before-request"`) and
standard DOM events (e.g., `"click"`).

Note: uses the `data-hx-on:<event>` form for HTML spec compliance.
"""
function hxon!(el::HTMLElement, event::AbstractString, script::AbstractString)
    el["data-hx-on:$event"] = script
    return el
end

# ──────────────────────────────────────────────
# hx-disable / hx-disabled-elt
# ──────────────────────────────────────────────

"""
    hxdisable!(el::HTMLElement) -> HTMLElement

Add an `hx-disable` attribute to prevent htmx from processing this element and its children.
Useful for including untrusted user content.
"""
function hxdisable!(el::HTMLElement)
    el[ensurehxprefix("disable")] = ""
    return el
end

"""
    hxdisabledelt!(el::HTMLElement, selector::AbstractString) -> HTMLElement

Add an `hx-disabled-elt` attribute to disable the specified elements during a request.

`selector` is a CSS selector for elements that should get the HTML `disabled` attribute
while a request is in flight (e.g., `"this"`, `"closest button"`, `"#submit-btn"`).
"""
hxdisabledelt!(el::HTMLElement, selector::AbstractString) = hxattr!(
    el, "disabled-elt", selector)

# ──────────────────────────────────────────────
# hx-disinherit / hx-inherit
# ──────────────────────────────────────────────

"""
    hxdisinherit!(el::HTMLElement, attrs::AbstractString) -> HTMLElement

Add an `hx-disinherit` attribute to disable automatic attribute inheritance for child nodes.

`attrs` can be `"*"` to disable all, or a space-separated list of attribute names
(e.g., `"hx-target hx-swap"`).
"""
hxdisinherit!(el::HTMLElement, attrs::AbstractString) = hxattr!(el, "disinherit", attrs)

"""
    hxinherit!(el::HTMLElement, attrs::AbstractString) -> HTMLElement

Add an `hx-inherit` attribute to explicitly enable attribute inheritance for child nodes
when `htmx.config.disableInheritance` is set to `true`.

`attrs` can be `"*"` to enable all, or a space-separated list of attribute names
(e.g., `"hx-target hx-swap"`).
"""
hxinherit!(el::HTMLElement, attrs::AbstractString) = hxattr!(el, "inherit", attrs)

# ──────────────────────────────────────────────
# hx-history / hx-history-elt
# ──────────────────────────────────────────────

"""
    hxhistory!(el::HTMLElement, value::AbstractString="false") -> HTMLElement

Add an `hx-history` attribute. Set to `"false"` to prevent sensitive data on this page
from being saved to the browser's history cache (`localStorage`).
"""
hxhistory!(el::HTMLElement, value::AbstractString = "false") = hxattr!(el, "history", value)

"""
    hxhistoryelt!(el::HTMLElement) -> HTMLElement

Add an `hx-history-elt` attribute to mark this element as the snapshot source/target
for history navigation (instead of the default `body`).
"""
function hxhistoryelt!(el::HTMLElement)
    el[ensurehxprefix("history-elt")] = ""
    return el
end

# ──────────────────────────────────────────────
# hx-preserve
# ──────────────────────────────────────────────

"""
    hxpreserve!(el::HTMLElement) -> HTMLElement

Add an `hx-preserve` attribute to keep this element unchanged between requests.
Useful for elements like video players that should maintain state across swaps.

Note: the element **must** have a stable `id` attribute.
"""
function hxpreserve!(el::HTMLElement)
    el[ensurehxprefix("preserve")] = ""
    return el
end

# ──────────────────────────────────────────────
# hx-request
# ──────────────────────────────────────────────

"""
    hxrequestconfig!(el::HTMLElement, value::AbstractString) -> HTMLElement

Add an `hx-request` attribute to configure various aspects of the request.

`value` is a JSON-like string, e.g., `\"timeout:3000, credentials:true\"` or
`\"noHeaders:true\"`.
"""
hxrequestconfig!(el::HTMLElement, value::AbstractString) = hxattr!(el, "request", value)

# ──────────────────────────────────────────────
# hx-validate
# ──────────────────────────────────────────────

"""
    hxvalidate!(el::HTMLElement) -> HTMLElement

Add an `hx-validate` attribute to force elements to validate themselves before a request.
This integrates with the HTML5 Validation API.
"""
function hxvalidate!(el::HTMLElement)
    el[ensurehxprefix("validate")] = "true"
    return el
end
