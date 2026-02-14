"""
    Experimental HTMX module — Full HTMX (625→<100 LOC) via Julia metaprogramming.

Provides three interfaces:
- **Classic**: `hxget!(el, url)`, `hxtrigger!(el, event; ...)`, etc.
- **`@hx` macro**: `@hx :button get="/api" trigger="click"`
- **Pipe DSL**: `el |> hx.get("/api") |> hx.trigger("click")`
"""
const _P = "data-hx-"
const _R = let v = :v, f = :f
    Dict{Symbol, Tuple{String, Symbol}}(
        :get => ("get", v), :post => ("post", v), :put => ("put", v),
        :patch => ("patch", v), :delete => ("delete", v),
        :target => ("target", v), :select => ("select", v), :swapoob => ("swap-oob", v),
        :selectoob => ("select-oob", v),
        :vals => ("vals", v), :pushurl => ("push-url", v), :replaceurl => ("replace-url", v),
        :confirm => ("confirm", v), :prompt => ("prompt", v), :indicator => ("indicator", v), :boost => (
            "boost", v),
        :include => ("include", v), :params => ("params", v), :headers => ("headers", v), :sync => (
            "sync", v),
        :encoding => ("encoding", v), :ext => ("ext", v), :disinherit => ("disinherit", v), :inherit => (
            "inherit", v),
        :history => ("history", v), :request => ("request", v), :disabledelt => (
            "disabled-elt", v),
        :disable => ("disable", f), :preserve => ("preserve", f), :validate => (
            "validate", f),
        :historyelt => ("history-elt", f)
    )
end

# ── 1. Code-gen all hx*!(el, [val]) from the registry ─────────────────────
for (name, (attr, kind)) in _R
    fn, full = Symbol(:hx, name, :!), _P * attr
    if kind == :v
        @eval $fn(el::HTMLElement, v::AbstractString) = (el[$full] = v; el)
    else
        @eval $fn(el::HTMLElement) = (el[$full] = ""; el)
    end
end
_hxnorm(a) = _P * replace(string(a), r"^(data-hx-|hx-)" => "")

"""
    hxattr!(el::HTMLElement, attr, value::AbstractString) -> HTMLElement

Set any htmx attribute on `el`. The `data-hx-` prefix is added/normalized automatically.
"""
function hxattr!(el::HTMLElement, a::Union{AbstractString, Symbol}, v::AbstractString)
    (el[_hxnorm(a)] = v; el)
end

"""
    hxrequest!(el::HTMLElement, method, url::AbstractString) -> HTMLElement

Set an htmx request attribute (`:get`, `:post`, `:put`, `:patch`, `:delete`).
"""
function hxrequest!(el::HTMLElement, m::Union{Symbol, AbstractString}, u::AbstractString)
    (el[_P * lowercase(string(m))] = u; el)
end

"""
    hxtrigger!(el::HTMLElement, event; once, changed, delay, throttle, from, target, consume, queue, filter)

Set `data-hx-trigger` with full modifier support.

# Example
```julia
hxtrigger!(el, "click"; once=true, delay="500ms")
# → data-hx-trigger="click once delay:500ms"
```
"""
function hxtrigger!(el::HTMLElement, event::AbstractString;
        once = false, changed = false, delay = nothing, throttle = nothing,
        from = nothing, target = nothing, consume = false, queue = nothing, filter = nothing)
    s = isnothing(filter) ? event : "$event[$filter]"
    mods = String[]
    once && push!(mods, "once")
    changed && push!(mods, "changed")
    for (k, v) in ((:delay, delay), (:throttle, throttle),
        (:from, from), (:target, target), (:queue, queue))
        isnothing(v) || push!(mods, "$k:$v")
    end
    consume && push!(mods, "consume")
    isempty(mods) || (s *= " " * join(mods, " "))
    el[_P * "trigger"] = s
    el
end

"""
    hxswap!(el::HTMLElement, style; transition, swap, settle, ignoreTitle, scroll, show, focusScroll)

Set `data-hx-swap` with validated style and optional modifiers.
Valid styles: `innerHTML`, `outerHTML`, `afterbegin`, `beforebegin`, `beforeend`, `afterend`, `delete`, `none`.
"""
const _SWAPS = Set(["innerHTML", "outerHTML", "afterbegin", "beforebegin",
    "beforeend", "afterend", "delete", "none"])
function hxswap!(el::HTMLElement, style::AbstractString;
        transition = nothing, swap = nothing, settle = nothing,
        ignoreTitle = nothing, scroll = nothing, show = nothing, focusScroll = nothing)
    style ∈ _SWAPS || throw(ArgumentError("Invalid swap style: \"$style\""))
    p = [style]
    for (k, v) in ((:transition, transition), (:swap, swap), (:settle, settle),
        (:ignoreTitle, ignoreTitle), (:scroll, scroll), (:show, show))
        isnothing(v) || push!(p, "$k:$(lowercase(string(v)))")
    end
    isnothing(focusScroll) || push!(p, "focus-scroll:$(lowercase(string(focusScroll)))")
    el[_P * "swap"] = join(p, " ")
    el
end

"""
    hxon!(el::HTMLElement, event::AbstractString, script::AbstractString) -> HTMLElement

Set `data-hx-on:<event>` for inline event handling.
"""
function hxon!(el::HTMLElement, ev::AbstractString, js::AbstractString)
    (el["data-hx-on:$ev"] = js; el)
end
load_trigger(el::HTMLElement; delay = nothing) = hxtrigger!(el, "load"; delay)
revealed_trigger(el::HTMLElement; once = true) = hxtrigger!(el, "revealed"; once)
poll_trigger(el::HTMLElement, iv::AbstractString) = hxtrigger!(el, "every $iv")
function intersect_trigger(
        el::HTMLElement; root = nothing, threshold = nothing, once = true)
    ev, opts = "intersect", String[]
    isnothing(root) || push!(opts, "root:$root")
    isnothing(threshold) || push!(opts, "threshold:$(clamp(Float64(threshold), 0.0, 1.0))")
    isempty(opts) || (ev *= "[$(join(opts, " "))]")
    hxtrigger!(el, ev; once)
end

"""
    @hx el key=value ...

Declare htmx attributes on an element. If `el` is a quoted symbol (e.g. `:button`),
a new `HTMLElement` is created. Otherwise, the existing variable is modified in place.
Underscores in keys become hyphens.

# Examples
```julia
btn = @hx :button get="/api" trigger="click" target="#result"
@hx existing_el post="/submit" swap="outerHTML"
@hx el push_url="true"   # → data-hx-push-url
```
"""
macro hx(el, attrs...)
    if el isa QuoteNode || (el isa Expr && el.head === :quote)
        init = :(HTMLElement($el))
    else
        init = esc(el)
    end
    blk = Any[:(local _e = $init)]
    for a in attrs
        a isa Expr && a.head == :(=) || error("@hx: expected key=value pairs, got: $a")
        push!(blk,
            :(_e[$_P * $(replace(string(a.args[1]), "_" => "-"))] = string($(esc(a.args[2])))))
    end
    push!(blk, :(_e))
    Expr(:block, blk...)
end

"""
    hx

Pipe-chain DSL singleton. Access htmx attributes as `hx.<name>(value)` and chain with `|>`.

# Example
```julia
el = HTMLElement(:button) |>
    hx.post("/submit") |>
    hx.target("#result") |>
    hx.swap("outerHTML"; transition=true) |>
    hx.trigger("click"; once=true)
```
"""
struct _HxPipe end;
const hx = _HxPipe();
function Base.getproperty(::_HxPipe, n::Symbol)
    if haskey(_R, n)
        a, k = _R[n]
        return k == :v ?
               (v::AbstractString) -> (el -> (el[_P * a] = v; el)) :
               () -> (el -> (el[_P * a] = ""; el))
    end
    n === :trigger &&
        return (ev::AbstractString; kw...) -> (el -> hxtrigger!(el, ev; kw...))
    n === :swap && return (st::AbstractString; kw...) -> (el -> hxswap!(el, st; kw...))
    n === :on && return (ev, s) -> (el -> hxon!(el, ev, s))
    error("Unknown htmx attribute: $n")
end
