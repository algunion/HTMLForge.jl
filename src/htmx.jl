################
# WIP / Do not use - Figuring out ergonomics
################

const HXPREFIX = "data-hx-"
const ALTERNATIVE_HXPREFIX = "hx-"

function ensurehxprefix(attr::Union{AbstractString, Symbol})
    attr_str = string(attr)
    startswith(attr_str, HXPREFIX) && return attr_str
    startswith(attr_str, ALTERNATIVE_HXPREFIX) &&
        return replace(attr_str, ALTERNATIVE_HXPREFIX => HXPREFIX)
    return HXPREFIX * attr_str
end

"""
    hxrequest!(el::HTMLElement, method::Symbol, url::AbstractString) -> HTMLElement
Add an htmx request attribute to an `HTMLElement` and return a new `HTMLElement`.

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

Add an `hx-get` attribute to an `HTMLElement` and return a new `HTMLElement`.
"""
hxget!(el::HTMLElement, url::AbstractString) = hxrequest!(el, :get, url)

"""
    hxpost!(el::HTMLElement, url::AbstractString) -> HTMLElement
Add an `hx-post` attribute to an `HTMLElement` and return a new `HTMLElement`.
"""
hxpost!(el::HTMLElement, url::AbstractString) = hxrequest!(el, :post, url)

"""
    hxput!(el::HTMLElement, url::AbstractString) -> HTMLElement
Add an `hx-put` attribute to an `HTMLElement` and return a new `HTMLElement`.
"""
hxput!(el::HTMLElement, url::AbstractString) = hxrequest!(el, :put, url)

"""
    hxpatch!(el::HTMLElement, url::AbstractString) -> HTMLElement
Add an `hx-patch` attribute to an `HTMLElement` and return a new `HTMLElement`.
"""
hxpatch!(el::HTMLElement, url::AbstractString) = hxrequest!(el, :patch, url)

"""
    hxdelete!(el::HTMLElement, url::AbstractString) -> HTMLElement
Add an `hx-delete` attribute to an `HTMLElement` and return a new `HTMLElement`.
"""
hxdelete!(el::HTMLElement, url::AbstractString) = hxrequest!(el, :delete, url)

"""
    hxtrigger(el::HTMLElement, event::AbstractString; 
              once::Bool=false, changed::Bool=false, 
              delay::Union{Nothing,AbstractString}=nothing,
              throttle::Union{Nothing,AbstractString}=nothing,
              from::Union{Nothing,AbstractString}=nothing,
              filter::Union{Nothing,AbstractString}=nothing) -> HTMLElement

Add an `hx-trigger` attribute to an `HTMLElement` with appropriate modifiers and return a new `HTMLElement`.

# Arguments
- `el`: The HTML element to add the trigger to
- `event`: The event name (e.g., "click", "mouseenter", "load", "revealed")
- `once`: Whether the trigger should only fire once
- `changed`: Whether the trigger should only fire if the value of the element has changed
- `delay`: A time interval (e.g., "1s") to wait before issuing the request
- `throttle`: A time interval (e.g., "1s") to throttle requests
- `from`: A CSS selector to listen for the event on a different element
- `filter`: A JavaScript expression to filter when the trigger fires (without brackets)

"""
function hxtrigger!(el::HTMLElement, event::AbstractString;
        once::Bool = false, changed::Bool = false,
        delay::Union{Nothing, AbstractString} = nothing,
        throttle::Union{Nothing, AbstractString} = nothing,
        from::Union{Nothing, AbstractString} = nothing,
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

    # Combine event with modifiers
    if !isempty(modifiers)
        trigger_value = "$trigger_value $(join(modifiers, " "))"
    end

    # Add the trigger attribute to the element
    el[ensurehxprefix("trigger")] = trigger_value
    return el
end

"""
    hxtrigger!(el::HTMLElement, event::AbstractString; kw...) -> HTMLElement

Add an `hx-trigger` attribute to an `HTMLElement` with appropriate modifiers in place and return the modified `HTMLElement`.
Takes the same arguments as `hxtrigger`.
"""
function hxtrigger!(el::HTMLElement, event::AbstractString; kw...)
    new_el = hxtrigger(el, event; kw...)
    trigger_value = new_el.attributes["data-hx-trigger"]
    merge!(el.attributes, Dict("data-hx-trigger" => trigger_value))
    el
end

"""
    load_trigger(el::HTMLElement; delay::Union{Nothing,AbstractString}=nothing) -> HTMLElement

Add a 'load' trigger to an element, optionally with a delay.

# Examples
```julia
# Trigger on load
div("Load content") |> load_trigger()

# Trigger on load with delay
div("Load after 1s") |> load_trigger(delay="1s")
```
"""
load_trigger(el::HTMLElement; delay::Union{Nothing, AbstractString} = nothing) = hxtrigger(
    el, "load"; delay = delay)

"""
    revealed_trigger(el::HTMLElement; once::Bool=true) -> HTMLElement

Add a 'revealed' trigger to an element (fires when element scrolls into view).
By default, this only triggers once.
"""
revealed_trigger(el::HTMLElement; once::Bool = true) = hxtrigger(
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

    hxtrigger(el, event; once = once)
end

"""
    poll_trigger(el::HTMLElement, interval::AbstractString) -> HTMLElement

Add a polling trigger to an element.

# Arguments
- `interval`: The polling interval (e.g., "2s", "500ms")

# Examples
```julia
# Poll every 2 seconds
div("Poll content") |> poll_trigger("2s")
```
"""
poll_trigger(el::HTMLElement, interval::AbstractString) = hxtrigger(el, "every $interval")
