# HTMLForge.jl — LLM Reference

> This page is a condensed, single-file reference for **HTMLForge.jl** (v0.3.13) optimized for LLM code-generation systems. It covers the full public API. Julia ≥ 1.8.

## Install

```julia
using Pkg; Pkg.add("HTMLForge")
using HTMLForge
```

---

## Type Hierarchy

```
HTMLNode (abstract)
├── HTMLElement{T}   # T is a Symbol tag, e.g. HTMLElement{:div}
├── HTMLText         # text node
└── NullNode         # sentinel for missing parents
```

### HTMLDocument

Returned by `parsehtml`. Fields:
- `doctype::AbstractString` — doctype string (empty if none)
- `root::HTMLElement` — root of the document tree

### HTMLElement{T}

```julia
mutable struct HTMLElement{T} <: HTMLNode
    children::Vector{HTMLNode}
    parent::HTMLNode
    attributes::Dict{AbstractString, AbstractString}
end
```

Constructors:
```julia
HTMLElement(:div)                                          # empty
HTMLElement(:div, HTMLText("hello"))                        # single child
HTMLElement(:p, [HTMLText("text")], Dict("class"=>"intro")) # children + attrs
HTMLElement(:div, HTMLNode[]; data_id="42", class="box")   # keyword attrs (underscores → hyphens)
```

Indexing:
```julia
el["class"] = "wide"   # set attribute
el[:class]             # get attribute → "wide"
el[1]                  # first child
```

### HTMLText

```julia
HTMLText("some text")  # parent defaults to NullNode()
```

---

## Parsing

### parsehtml

```julia
parsehtml(html::String;
    strict=false,              # throw InvalidHTMLException on errors
    preserve_whitespace=false, # keep whitespace text nodes
    preserve_template=false,   # preserve <template> elements
    include_parent=true        # set parent references
) → HTMLDocument
```

### parsehtml_snippet

```julia
parsehtml_snippet(html::String;
    preserve_whitespace=false,
    preserve_template=false
) → HTMLElement
```

Returns an `HTMLElement`. Multiple top-level tags are wrapped in a `<div>`.

---

## Manipulation

### Element properties

```julia
tag(el)                    # → Symbol (:div, :p, etc.)
attrs(el)                  # → Dict of attributes
getattr(el, name)          # → value or nothing
getattr(el, name, default) # → value or default
setattr!(el, name, value)  # set attribute (validated)
hasattr(el, name)          # → Bool
children(el)               # → Vector{HTMLNode}
text(el)                   # recursively extract all text
```

### Finding elements

```julia
findfirst(f, el)           # first descendant matching predicate f (pre-order DFS)
findfirst(f, doc)          # same, starting from doc
getbyid(el_or_doc, id)    # find element by id attribute
applyif!(cond, f!, el_or_doc) # apply mutating f! to all elements matching cond
```

### CSS class helpers

```julia
hasclass(el, cls)          # → Bool
addclass!(el, cls)         # add class (no-op if present)
removeclass!(el, cls)      # remove class
replaceclass!(el, old, new) # replace; pass nothing to just remove
```

### Validation

```julia
@validate :attr "data-value"          # validate attribute name
@validate :class "my-class"           # validate class name
@validate :attr ["a", "b"]           # validate multiple attribute names
@validate :class ["c1", "c2"]        # validate multiple class names
```

Invalid names raise `InvalidAttributeException`. Invalid class values raise `ArgumentError` or `InvalidAttributeException`.

### Pretty printing

```julia
prettyprint(el)            # print to stdout
prettyprint(io, el)        # print to IO
prettyprint(doc)           # works on documents too
```

---

## Tree Traversal

Re-exported from AbstractTrees.jl:

```julia
preorder(node)             # pre-order DFS
postorder(node)            # post-order DFS
breadthfirst(node)         # breadth-first (level-order)
```

Use with `for elem in preorder(doc.root) ... end`.

---

## Equality

`HTMLDocument`, `HTMLElement`, and `HTMLText` support `==`, `isequal`, `hash`. Elements are equal when they have the same tag, attributes, and children (parents are ignored).

---

## HTMX Support

All HTMX helpers **mutate in place** and **return the element** (enabling chaining). Attributes are stored with the `data-hx-` prefix.

### Generic setter

```julia
hxattr!(el, attr, value)   # data-hx-<attr>="value"
```

### AJAX request helpers

```julia
hxget!(el, url)            # data-hx-get
hxpost!(el, url)           # data-hx-post
hxput!(el, url)            # data-hx-put
hxpatch!(el, url)          # data-hx-patch
hxdelete!(el, url)         # data-hx-delete
hxrequest!(el, method, url) # data-hx-<method>
```

### Trigger

```julia
hxtrigger!(el, event;
    once=false, changed=false, delay=nothing, throttle=nothing,
    from=nothing, target=nothing, consume=false, queue=nothing,
    filter=nothing
)
# Example: hxtrigger!(el, "click"; once=true, delay="500ms")
# → data-hx-trigger="click once delay:500ms"
# Filter: hxtrigger!(el, "click"; filter="ctrlKey")
# → data-hx-trigger="click[ctrlKey]"
```

### Target & swap

```julia
hxtarget!(el, selector)    # CSS selector, "this", "closest ...", etc.

hxswap!(el, style;
    transition=nothing, swap=nothing, settle=nothing,
    ignoreTitle=nothing, scroll=nothing, show=nothing,
    focusScroll=nothing
)
# Valid styles: "innerHTML", "outerHTML", "afterbegin", "beforebegin",
#               "beforeend", "afterend", "delete", "none"
# Example: hxswap!(el, "innerHTML"; transition=true, settle="100ms")

hxswapoob!(el, value)     # out-of-band swap
hxselect!(el, selector)   # select subset of response
hxselectoob!(el, sels)    # out-of-band select
```

### Values & URLs

```julia
hxvals!(el, json)          # additional values (JSON string)
hxpushurl!(el, value)      # push URL ("true", "false", or URL)
hxreplaceurl!(el, value)   # replace URL without history entry
```

### User interaction

```julia
hxconfirm!(el, message)    # confirm() dialog
hxprompt!(el, message)     # prompt() dialog
hxindicator!(el, selector) # element to show during request
```

### Progressive enhancement & parameters

```julia
hxboost!(el, value)        # "true"/"false"
hxinclude!(el, selector)   # include other elements' values
hxparams!(el, value)       # "*", "none", specific list, "not ..."
hxheaders!(el, json)       # additional headers (JSON)
hxsync!(el, value)         # e.g. "closest form:abort"
hxencoding!(el, encoding)  # e.g. "multipart/form-data"
hxext!(el, extensions)     # comma-separated extension list
```

### Event handling

```julia
hxon!(el, event, script)   # data-hx-on:<event>="script"
```

### Disable & inheritance

```julia
hxdisable!(el)             # disable htmx on element+children
hxdisabledelt!(el, sel)    # disable elements during request
hxdisinherit!(el, attrs)   # disable inheritance ("*" or space-separated)
hxinherit!(el, attrs)      # enable inheritance
```

### History & preservation

```julia
hxhistory!(el, value)      # "false" to prevent caching
hxhistoryelt!(el)          # mark as history snapshot source
hxpreserve!(el)            # keep unchanged between requests (needs stable id)
```

### Request config & validation

```julia
hxrequestconfig!(el, val)  # e.g. "timeout:3000, credentials:true"
hxvalidate!(el)            # enable HTML5 validation before request
```

### Chaining

```julia
el = HTMLElement(:button)
el |> x -> hxpost!(x, "/submit") |>
     x -> hxtarget!(x, "#result") |>
     x -> hxswap!(x, "outerHTML") |>
     x -> hxconfirm!(x, "Sure?")
```

---

## Experimental HTMX Module

Three additional interfaces. Load with:

```julia
using HTMLForge
include(joinpath(pkgdir(HTMLForge), "src", "Experimental.jl"))
```

### Interface 1: Classic functions (auto-generated)

Same as standard API above — all `hx*!` functions are generated via `@eval` from an internal registry.

### Interface 2: `@hx` macro

Declarative multi-attribute assignment:

```julia
# Create + assign
btn = @hx :button get="/api" trigger="click" target="#result"

# Modify existing
el = HTMLElement(:form)
@hx el post="/submit" swap="outerHTML" confirm="Sure?"

# Underscores → hyphens
@hx el push_url="true" replace_url="/new"

# Expression interpolation
url = "/api/v2"
btn = @hx :button get=url
```

> **Note**: `@hx` sets raw string values. Trigger modifiers must be in the string: `trigger="click once delay:500ms"`.

### Interface 3: `hx.*` pipe DSL

Most ergonomic — uses `|>` with curried closures:

```julia
el = HTMLElement(:button) |>
    hx.post("/api/submit") |>
    hx.trigger("click"; once=true) |>
    hx.target("#response") |>
    hx.swap("outerHTML"; transition=true, settle="200ms") |>
    hx.confirm("Proceed?") |>
    hx.indicator("#spinner")
```

Flag attributes: `hx.disable()`, `hx.preserve()`, `hx.validate()`, `hx.historyelt()`.

### Side-by-side comparison

```julia
# Classic
el = HTMLElement(:button)
hxpost!(el, "/submit")
hxtarget!(el, "#result")
hxswap!(el, "outerHTML")
hxtrigger!(el, "click"; once=true)
hxconfirm!(el, "Sure?")

# @hx macro
el = @hx :button post="/submit" target="#result" swap="outerHTML" trigger="click once" confirm="Sure?"

# Pipe DSL
el = HTMLElement(:button) |>
    hx.post("/submit") |>
    hx.target("#result") |>
    hx.swap("outerHTML") |>
    hx.trigger("click"; once=true) |>
    hx.confirm("Sure?")
```

---

## Complete HTMX Attribute Table

### Value attributes

| Function                  | Attribute              | Pipe                |
| ------------------------- | ---------------------- | ------------------- |
| `hxget!(el, v)`           | `data-hx-get`          | `hx.get(v)`         |
| `hxpost!(el, v)`          | `data-hx-post`         | `hx.post(v)`        |
| `hxput!(el, v)`           | `data-hx-put`          | `hx.put(v)`         |
| `hxpatch!(el, v)`         | `data-hx-patch`        | `hx.patch(v)`       |
| `hxdelete!(el, v)`        | `data-hx-delete`       | `hx.delete(v)`      |
| `hxtarget!(el, v)`        | `data-hx-target`       | `hx.target(v)`      |
| `hxselect!(el, v)`        | `data-hx-select`       | `hx.select(v)`      |
| `hxswapoob!(el, v)`       | `data-hx-swap-oob`     | `hx.swapoob(v)`     |
| `hxselectoob!(el, v)`     | `data-hx-select-oob`   | `hx.selectoob(v)`   |
| `hxvals!(el, v)`          | `data-hx-vals`         | `hx.vals(v)`        |
| `hxpushurl!(el, v)`       | `data-hx-push-url`     | `hx.pushurl(v)`     |
| `hxreplaceurl!(el, v)`    | `data-hx-replace-url`  | `hx.replaceurl(v)`  |
| `hxconfirm!(el, v)`       | `data-hx-confirm`      | `hx.confirm(v)`     |
| `hxprompt!(el, v)`        | `data-hx-prompt`       | `hx.prompt(v)`      |
| `hxindicator!(el, v)`     | `data-hx-indicator`    | `hx.indicator(v)`   |
| `hxboost!(el, v)`         | `data-hx-boost`        | `hx.boost(v)`       |
| `hxinclude!(el, v)`       | `data-hx-include`      | `hx.include(v)`     |
| `hxparams!(el, v)`        | `data-hx-params`       | `hx.params(v)`      |
| `hxheaders!(el, v)`       | `data-hx-headers`      | `hx.headers(v)`     |
| `hxsync!(el, v)`          | `data-hx-sync`         | `hx.sync(v)`        |
| `hxencoding!(el, v)`      | `data-hx-encoding`     | `hx.encoding(v)`    |
| `hxext!(el, v)`           | `data-hx-ext`          | `hx.ext(v)`         |
| `hxdisinherit!(el, v)`    | `data-hx-disinherit`   | `hx.disinherit(v)`  |
| `hxinherit!(el, v)`       | `data-hx-inherit`      | `hx.inherit(v)`     |
| `hxhistory!(el, v)`       | `data-hx-history`      | `hx.history(v)`     |
| `hxrequestconfig!(el, v)` | `data-hx-request`      | `hx.request(v)`     |
| `hxdisabledelt!(el, v)`   | `data-hx-disabled-elt` | `hx.disabledelt(v)` |

### Flag attributes (no argument)

| Function            | Attribute             | Pipe              |
| ------------------- | --------------------- | ----------------- |
| `hxdisable!(el)`    | `data-hx-disable`     | `hx.disable()`    |
| `hxpreserve!(el)`   | `data-hx-preserve`    | `hx.preserve()`   |
| `hxvalidate!(el)`   | `data-hx-validate`    | `hx.validate()`   |
| `hxhistoryelt!(el)` | `data-hx-history-elt` | `hx.historyelt()` |

### Complex attributes (keyword arguments)

| Function                     | Pipe                     | kwargs                                                                                 |
| ---------------------------- | ------------------------ | -------------------------------------------------------------------------------------- |
| `hxtrigger!(el, event; ...)` | `hx.trigger(event; ...)` | `once`, `changed`, `delay`, `throttle`, `from`, `target`, `consume`, `queue`, `filter` |
| `hxswap!(el, style; ...)`    | `hx.swap(style; ...)`    | `transition`, `swap`, `settle`, `ignoreTitle`, `scroll`, `show`, `focusScroll`         |
| `hxon!(el, event, script)`   | `hx.on(event, script)`   | —                                                                                      |

---

## Common Patterns

### Parse → find → modify → print

```julia
doc = parsehtml(read("page.html", String))
el = getbyid(doc, "main-content")
addclass!(el, "active")
hxget!(el, "/api/refresh")
hxtarget!(el, "#content")
prettyprint(doc)
```

### Build an element tree from scratch

```julia
div = HTMLElement(:div)
div["class"] = "container"

header = HTMLElement(:h1, HTMLText("Title"))
push!(div, header)

btn = HTMLElement(:button, HTMLText("Click me"))
hxpost!(btn, "/api/action")
hxtarget!(btn, "#result")
hxswap!(btn, "innerHTML")
push!(div, btn)

result = HTMLElement(:div)
result["id"] = "result"
push!(div, result)

prettyprint(div)
```

### Traverse and transform

```julia
doc = parsehtml(html_string)
for el in preorder(doc.root)
    if isa(el, HTMLElement) && tag(el) == :a
        hxboost!(el, "true")
    end
end
```

### Apply a change to all matching elements

```julia
applyif!(el -> tag(el) == :form, el -> hxboost!(el, "true"), doc)
```

### Experimental pipe DSL full example

```julia
using HTMLForge
include(joinpath(pkgdir(HTMLForge), "src", "Experimental.jl"))

form = HTMLElement(:form) |>
    hx.post("/api/submit") |>
    hx.target("#result") |>
    hx.swap("outerHTML"; transition=true) |>
    hx.trigger("submit"; once=true) |>
    hx.confirm("Submit form?") |>
    hx.indicator("#spinner")
```
