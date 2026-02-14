# Experimental HTMX

!!! warning "Experimental"
    This module uses advanced Julia metaprogramming (macros, `@eval` code generation, `Base.getproperty` overloading) to compress the full 625-line HTMX API into **under 100 lines of code**. The interfaces are experimental and may evolve.

The Experimental module provides **three interfaces** for working with HTMX attributes. All three produce identical results — choose the style that fits your workflow.

## Setup

The experimental module is included separately from the main HTMX API:

```julia
using HTMLForge
include(joinpath(pkgdir(HTMLForge), "src", "Experimental.jl"))
```

## Interface 1: Classic Functions

All `hx*!` functions from the standard API are auto-generated via `@eval` loop over an attribute registry. They work identically to the standard API:

```julia
el = HTMLElement(:button)
hxget!(el, "/api/data")
hxpost!(el, "/submit")
hxtarget!(el, "#result")
hxswap!(el, "outerHTML"; transition=true, settle="100ms")
hxtrigger!(el, "click"; once=true, delay="500ms")
hxconfirm!(el, "Are you sure?")
```

Flag attributes (no value needed):

```julia
hxdisable!(el)     # data-hx-disable=""
hxpreserve!(el)    # data-hx-preserve=""
hxvalidate!(el)    # data-hx-validate=""
```

### How it works

A registry `Dict{Symbol, Tuple{String, Symbol}}` maps attribute names to their htmx suffix and kind (`:v` for value-taking, `:f` for flag). A single `for` loop with `@eval` generates all 30+ functions at compile time:

```julia
for (name, (attr, kind)) in _R
    fn, full = Symbol(:hx, name, :!), "data-hx-" * attr
    if kind == :v
        @eval \$fn(el::HTMLElement, v::AbstractString) = (el[\$full] = v; el)
    else
        @eval \$fn(el::HTMLElement) = (el[\$full] = ""; el)
    end
end
```

## Interface 2: `@hx` Macro

The `@hx` macro enables **declarative, multi-attribute assignment** in a single expression.

### Creating a new element

Pass a symbol to simultaneously create an element and set attributes:

```julia
btn = @hx :button get="/api" trigger="click" target="#result"
# Equivalent to:
#   btn = HTMLElement(:button)
#   btn["data-hx-get"] = "/api"
#   btn["data-hx-trigger"] = "click"
#   btn["data-hx-target"] = "#result"
```

### Modifying an existing element

Pass a variable to modify it in place:

```julia
el = HTMLElement(:form)
@hx el post="/submit" swap="outerHTML" confirm="Sure?"
```

### Underscores become hyphens

Use underscores in attribute names — they are automatically converted to hyphens:

```julia
@hx el push_url="true" replace_url="/new"
# → data-hx-push-url="true", data-hx-replace-url="/new"
```

### Expression interpolation

Values can be any Julia expression:

```julia
url = "/api/v2/items"
btn = @hx :button get=url
```

### How it works

The macro inspects its first argument at compile time:
- **`QuoteNode`** (e.g. `:button`) → generates `HTMLElement(:button)`
- **anything else** → `esc(el)` to use the existing variable

It then iterates over the `key=value` pairs, converting them to `el["data-hx-key"] = string(value)` assignments. The entire expansion is a `begin...end` block returning the element.

## Interface 3: `hx.*` Pipe DSL

The most ergonomic interface — chain htmx attributes with Julia's `|>` operator using the `hx` singleton:

```julia
el = HTMLElement(:button) |>
    hx.post("/api/submit") |>
    hx.trigger("click"; once=true) |>
    hx.target("#response") |>
    hx.swap("outerHTML"; transition=true, settle="200ms") |>
    hx.confirm("Proceed?") |>
    hx.indicator("#spinner")
```

### Value attributes

Every registered attribute is accessible as `hx.<name>(value)`:

```julia
el |> hx.get("/api")
el |> hx.target("#out")
el |> hx.boost("true")
el |> hx.pushurl("true")
el |> hx.headers("{\"X-Token\": \"abc\"}")
```

### Flag attributes

Flag attributes take no arguments:

```julia
el |> hx.disable()
el |> hx.preserve()
el |> hx.validate()
```

### Complex attributes

`hx.trigger`, `hx.swap`, and `hx.on` support the same keyword arguments as their function counterparts:

```julia
el |> hx.trigger("keyup"; delay="300ms", changed=true)
el |> hx.swap("innerHTML"; transition=true, focusScroll=false)
el |> hx.on("click", "console.log('clicked')")
```

### How it works

`hx` is a zero-size singleton struct `_HxPipe`. A `Base.getproperty` override intercepts `hx.foo` and returns a **curried closure**: calling `hx.get("/api")` returns `el -> (el["data-hx-get"] = "/api"; el)`, which is exactly the signature `|>` expects. For `trigger` and `swap`, the closures forward keyword arguments to the full `hxtrigger!` / `hxswap!` implementations.

## Complete Comparison

Here's the same element built with all three interfaces:

```julia
# Classic
el = HTMLElement(:button)
hxpost!(el, "/submit")
hxtarget!(el, "#result")
hxswap!(el, "outerHTML")
hxtrigger!(el, "click"; once=true)
hxconfirm!(el, "Sure?")

# @hx macro
el = @hx :button post="/submit" target="#result" swap="outerHTML" trigger="click" confirm="Sure?"

# Pipe DSL
el = HTMLElement(:button) |>
    hx.post("/submit") |>
    hx.target("#result") |>
    hx.swap("outerHTML") |>
    hx.trigger("click"; once=true) |>
    hx.confirm("Sure?")
```

## Supported Attributes

### Value Attributes (take a string argument)

| Function              | htmx attribute         | Pipe                  |
| --------------------- | ---------------------- | --------------------- |
| `hxget!`              | `data-hx-get`          | `hx.get(url)`         |
| `hxpost!`             | `data-hx-post`         | `hx.post(url)`        |
| `hxput!`              | `data-hx-put`          | `hx.put(url)`         |
| `hxpatch!`            | `data-hx-patch`        | `hx.patch(url)`       |
| `hxdelete!`           | `data-hx-delete`       | `hx.delete(url)`      |
| `hxtarget!`           | `data-hx-target`       | `hx.target(sel)`      |
| `hxselect!`           | `data-hx-select`       | `hx.select(sel)`      |
| `hxswapoob!`          | `data-hx-swap-oob`     | `hx.swapoob(v)`       |
| `hxselectoob!`        | `data-hx-select-oob`   | `hx.selectoob(v)`     |
| `hxvals!`             | `data-hx-vals`         | `hx.vals(json)`       |
| `hxpushurl!`          | `data-hx-push-url`     | `hx.pushurl(v)`       |
| `hxreplaceurl!`       | `data-hx-replace-url`  | `hx.replaceurl(v)`    |
| `hxconfirm!`          | `data-hx-confirm`      | `hx.confirm(msg)`     |
| `hxprompt!`           | `data-hx-prompt`       | `hx.prompt(msg)`      |
| `hxindicator!`        | `data-hx-indicator`    | `hx.indicator(sel)`   |
| `hxboost!`            | `data-hx-boost`        | `hx.boost(v)`         |
| `hxinclude!`          | `data-hx-include`      | `hx.include(sel)`     |
| `hxparams!`           | `data-hx-params`       | `hx.params(v)`        |
| `hxheaders!`          | `data-hx-headers`      | `hx.headers(json)`    |
| `hxsync!`             | `data-hx-sync`         | `hx.sync(v)`          |
| `hxencoding!`         | `data-hx-encoding`     | `hx.encoding(v)`      |
| `hxext!`              | `data-hx-ext`          | `hx.ext(v)`           |
| `hxdisinherit!`       | `data-hx-disinherit`   | `hx.disinherit(v)`    |
| `hxinherit!`          | `data-hx-inherit`      | `hx.inherit(v)`       |
| `hxhistory!`          | `data-hx-history`      | `hx.history(v)`       |
| `hxrequest!` (config) | `data-hx-request`      | `hx.request(v)`       |
| `hxdisabledelt!`      | `data-hx-disabled-elt` | `hx.disabledelt(sel)` |

### Flag Attributes (no argument)

| Function        | htmx attribute        | Pipe              |
| --------------- | --------------------- | ----------------- |
| `hxdisable!`    | `data-hx-disable`     | `hx.disable()`    |
| `hxpreserve!`   | `data-hx-preserve`    | `hx.preserve()`   |
| `hxvalidate!`   | `data-hx-validate`    | `hx.validate()`   |
| `hxhistoryelt!` | `data-hx-history-elt` | `hx.historyelt()` |

### Complex Attributes (with keyword arguments)

| Function                     | Pipe                     | Supports kwargs                                                                        |
| ---------------------------- | ------------------------ | -------------------------------------------------------------------------------------- |
| `hxtrigger!(el, event; ...)` | `hx.trigger(event; ...)` | `once`, `changed`, `delay`, `throttle`, `from`, `target`, `consume`, `queue`, `filter` |
| `hxswap!(el, style; ...)`    | `hx.swap(style; ...)`    | `transition`, `swap`, `settle`, `ignoreTitle`, `scroll`, `show`, `focusScroll`         |
| `hxon!(el, event, script)`   | `hx.on(event, script)`   | —                                                                                      |

## Metaprogramming Techniques Used

| Technique                      | Where                   | Purpose                                                           |
| ------------------------------ | ----------------------- | ----------------------------------------------------------------- |
| `@eval` in a loop              | Function generation     | Generate 30+ `hx*!` functions from a registry Dict                |
| `Symbol` arithmetic            | `Symbol(:hx, name, :!)` | Dynamic function naming                                           |
| `macro` with AST introspection | `@hx`                   | Detect `QuoteNode` vs variable to choose creation vs modification |
| `Base.getproperty` overloading | `hx.*` pipe DSL         | Create a callable namespace on a zero-size singleton              |
| Curried closures               | Pipe DSL                | Return `el -> ...` functions compatible with `\|>`                |
