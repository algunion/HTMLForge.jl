# HTMLForge.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://algunion.github.io/HTMLForge.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://algunion.github.io/HTMLForge.jl/dev/)
[![codecov](https://codecov.io/gh/algunion/HTMLForge.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/algunion/HTMLForge.jl)

HTMLForge.jl is a Julia wrapper around the
[Gumbo library](https://codeberg.org/gumbo-parser/gumbo-parser) for
parsing HTML, with first-class support for [HTMX](https://htmx.org/) attributes.

## Important Note

HTMLForge is a fork of the Gumbo.jl project with the goal of extending it in ways that currently serve my own needs. For example, making HTMX a first class citizen in HTMLForge — by adding types, functions and relevant syntax sugar to make it easy to work with HTMX in Julia/HTMLForge.

### Getting started

Getting started is very easy:

```julia
julia> using HTMLForge

julia> parsehtml("<h1> Hello, world! </h1>")
HTML Document:
<!DOCTYPE >
HTMLElement{:HTML}:
<HTML>
  <head></head>
  <body>
    <h1>
       Hello, world!
    </h1>
  </body>
</HTML>
```

Read on for further documentation.

## Installation

```jl
using Pkg
Pkg.add("HTMLForge")
```

or activate `Pkg` mode in the REPL by typing `]`, and then:

```shell
add HTMLForge
```

## Basic usage

### Parsing a full document

The workhorse is the `parsehtml` function, which takes a single
argument, a valid UTF8 string, which is interpreted as HTML data to be
parsed, e.g.:

```julia
parsehtml("<h1> Hello, world! </h1>")
```

Parsing an HTML file named `filename` can be done using:

```julia
julia> parsehtml(read(filename, String))
```

The result of a call to `parsehtml` is an `HTMLDocument`, a type which
has two fields: `doctype`, which is the doctype of the parsed document
(this will be the empty string if no doctype is provided), and `root`,
which is a reference to the `HTMLElement` that is the root of the
document.

Note that HTMLForge is a very permissive HTML parser, designed to
gracefully handle the insanity that passes for HTML out on the wild,
wild web. It will return a valid HTML document for *any* input, doing
all sorts of algorithmic gymnastics to twist what you give it into
valid HTML.

If you want an HTML validator, this is probably not your library. That
said, `parsehtml` does take an optional `Bool` keyword argument,
`strict` which, if `true`, causes an `InvalidHTMLException` to be thrown
if the call to the Gumbo C library produces any errors.

#### Additional keyword arguments

| Keyword               | Type   | Default | Description                                      |
| --------------------- | ------ | ------- | ------------------------------------------------ |
| `strict`              | `Bool` | `false` | Throw `InvalidHTMLException` on parse errors     |
| `preserve_whitespace` | `Bool` | `false` | Keep whitespace text nodes (e.g. inside `<pre>`) |
| `preserve_template`   | `Bool` | `false` | Preserve `<template>` elements in the tree       |
| `include_parent`      | `Bool` | `true`  | Set parent references on child nodes             |

### Parsing an HTML snippet

`parsehtml_snippet` parses an HTML fragment (not a full document) and
returns an `HTMLElement` rather than an `HTMLDocument`:

```julia
julia> parsehtml_snippet("<p>Hello</p>")
HTMLElement{:p}:
<p>
  Hello
</p>
```

If the snippet contains multiple top-level tags, they are wrapped in a
`<div>`:

```julia
julia> parsehtml_snippet("<p>A</p><p>B</p>")
HTMLElement{:div}:
<div>
  <p>
    A
  </p>
  <p>
    B
  </p>
</div>
```

`parsehtml_snippet` accepts the same `preserve_whitespace` and
`preserve_template` keyword arguments as `parsehtml`.

## HTML types

This library defines a number of types for representing HTML.

### `HTMLDocument`

`HTMLDocument` is what is returned from a call to `parsehtml`. It has a
`doctype` field, which contains the doctype of the parsed document,
and a `root` field, which is a reference to the root of the document.

### `HTMLNode`s

A document contains a tree of HTML Nodes, which are represented as
children of the `HTMLNode` abstract type. The first of these is
`HTMLElement`.

### `HTMLElement`

```julia
mutable struct HTMLElement{T} <: HTMLNode
    children::Vector{HTMLNode}
    parent::HTMLNode
    attributes::Dict{AbstractString, AbstractString}
end
```

`HTMLElement` is probably the most interesting and frequently used
type. An `HTMLElement` is parameterized by a symbol representing its
tag. So an `HTMLElement{:a}` is a different type from an
`HTMLElement{:body}`, etc. An empty `HTMLElement` of a given tag can be
constructed as follows:

```julia
julia> HTMLElement(:div)
HTMLElement{:div}:
<div></div>
```

There are several constructors available:

```julia
# Empty element
HTMLElement(:div)

# Element with a single child
HTMLElement(:div, HTMLText("hello"))

# Element with children and attributes
HTMLElement(:p, [HTMLText("text")], Dict("class" => "intro"))

# Element with children and keyword attributes (underscores become hyphens)
HTMLElement(:div, HTMLNode[]; data_id="42", class="box")
```

`HTMLElement`s have a `parent` field, which refers to another
`HTMLNode`. `parent` will always be an `HTMLElement`, unless the
element has no parent (as is the case with the root of a document), in
which case it will be a `NullNode`, a special type of `HTMLNode` which
exists for just this purpose. Empty `HTMLElement`s constructed as in
the example above will also have a `NullNode` for a parent.

`HTMLElement`s also have `children`, which is a vector of
`HTMLNode` containing the children of this element, and
`attributes`, which is a `Dict` mapping attribute names to values.

`HTMLElement`s implement `getindex`, `setindex!`, and `push!`;
indexing into or pushing onto an `HTMLElement` operates on its
children array. You can also index with a string or symbol key to
access attributes directly:

```julia
el = HTMLElement(:div)
el["class"] = "wide"   # set attribute
el[:class]             # get attribute → "wide"
```

There are a number of convenience methods for working with `HTMLElement`s:

- `tag(elem)` — get the tag of this element as a symbol

- `attrs(elem)` — return the attributes dict of this element

- `children(elem)` — return the children array of this element

- `getattr(elem, name)` — get the value of attribute `name`, or
  `nothing` if not present. Also supports a default value:
  `getattr(elem, name, default)`.

- `setattr!(elem, name, value)` — set the value of attribute `name`
  to `value`. Attribute names are validated automatically.

- `hasattr(elem, name)` — check whether an element has an attribute

- `text(elem)` — recursively extract all text content from the
  element and its descendants

- `prettyprint(elem)` / `prettyprint(io, elem)` — pretty-print an
  element with indentation

### `HTMLText`

```julia
mutable struct HTMLText <: HTMLNode
    parent::HTMLNode
    text::AbstractString
end
```

Represents text appearing in an HTML document. For example:

```julia
julia> doc = parsehtml("<h1> Hello, world! </h1>")

julia> doc.root[2][1][1]
HTML Text: ` Hello, world! `
```

This type is quite simple, just a reference to its parent and the
actual text it represents (also accessible via the `text` function).
You can construct `HTMLText` instances as follows:

```julia
julia> HTMLText("Example text")
HTML Text: `Example text`
```

Just as with `HTMLElement`s, the parent of an instance so constructed
will be a `NullNode`.

## Searching and manipulation

HTMLForge provides several functions for finding and modifying elements
in a parsed document:

### Finding elements

- `findfirst(f, elem)` / `findfirst(f, doc)` — find the first element
  (pre-order DFS) for which `f` returns `true`:

  ```julia
  findfirst(x -> tag(x) == :a, doc.root)
  ```

- `getbyid(elem, id)` / `getbyid(doc, id)` — find an element by its
  `id` attribute:

  ```julia
  getbyid(doc, "main-content")
  ```

### Modifying elements

- `applyif!(condition, f!, elem)` / `applyif!(condition, f!, doc)` —
  apply a mutating function to all elements matching a condition:

  ```julia
  applyif!(x -> tag(x) == :div, x -> setattr!(x, "class", "wide"), doc)
  ```

### CSS class helpers

- `hasclass(elem, cls)` — check if element has a CSS class
- `addclass!(elem, cls)` — add a CSS class (no-op if already present)
- `removeclass!(elem, cls)` — remove a CSS class
- `replaceclass!(elem, old, new)` — replace one class with another;
  pass `nothing` as the new class to simply remove the old one

```julia
el = HTMLElement(:div)
addclass!(el, "active")
addclass!(el, "highlight")
hasclass(el, "active")       # true
replaceclass!(el, "active", "inactive")
removeclass!(el, "highlight")
```

## Validation

Attribute names and CSS class values are validated automatically when
using `setattr!`, `addclass!`, `replaceclass!`, and bracket assignment
(`el["..."] = ...`). Invalid characters (spaces, `>`, `=`, quotes, etc.)
in attribute names will raise `InvalidAttributeException`. Invalid class
values (empty or containing whitespace) will raise `ArgumentError` or
`InvalidAttributeException`.

You can also use the `@validate` macro directly:

```julia
@validate :attr "data-value"          # validate attribute name
@validate :class "my-class"           # validate class name
@validate :attr ["id", "data-value"]  # validate multiple attribute names
@validate :class ["cls1", "cls2"]     # validate multiple class names
```

## Comparison and equality

`HTMLDocument`, `HTMLElement`, and `HTMLText` all support `==`,
`isequal`, and `hash`. Two elements are considered equal if they have
the same tag, attributes, and children (parents are ignored for
equality purposes):

```julia
HTMLElement(:div) == HTMLElement(:div)  # true
```

## Tree traversal

HTMLForge re-exports convenience aliases for common tree traversal
strategies:

- `preorder(node)` — pre-order depth-first traversal
- `postorder(node)` — post-order depth-first traversal
- `breadthfirst(node)` — breadth-first (level-order) traversal

```julia
using HTMLForge

doc = parsehtml("""
    <html>
      <body>
        <div>
          <p></p> <a></a> <p></p>
        </div>
        <div>
          <span></span>
        </div>
      </body>
    </html>
    """);

for elem in preorder(doc.root) println(tag(elem)) end
# HTML, head, body, div, p, a, p, div, span

for elem in postorder(doc.root) println(tag(elem)) end
# head, p, a, p, div, span, div, body, HTML

for elem in breadthfirst(doc.root) println(tag(elem)) end
# HTML, head, body, div, div, p, a, p, span
```

You can also use the iterators from
[AbstractTrees.jl](https://github.com/Keno/AbstractTrees.jl/) directly
(`PreOrderDFS`, `PostOrderDFS`, `StatelessBFS`).

## Pretty printing

Use `prettyprint` to output nicely indented HTML:

```julia
prettyprint(doc)              # print document to stdout
prettyprint(io, doc)          # print document to an IO stream
prettyprint(elem)             # print element to stdout
prettyprint(io, elem)         # print element to an IO stream
```

## HTMX support

HTMLForge treats [HTMX](https://htmx.org/) as a first-class citizen.
All HTMX attribute helpers mutate the element in place and return it,
enabling a chaining style. Attributes are stored with the `data-hx-`
prefix for HTML spec compliance.

### Generic attribute setter

```julia
hxattr!(el, attr, value)
```

Set any htmx attribute. The `data-hx-` prefix is added automatically:

```julia
el = HTMLElement(:div)
hxattr!(el, "custom", "value")
# → sets data-hx-custom="value"
```

### AJAX request helpers

```julia
hxget!(el, url)       # data-hx-get
hxpost!(el, url)      # data-hx-post
hxput!(el, url)       # data-hx-put
hxpatch!(el, url)     # data-hx-patch
hxdelete!(el, url)    # data-hx-delete
```

Or use the generic version with a method symbol:

```julia
hxrequest!(el, :get, "/api/items")
```

### Trigger

```julia
hxtrigger!(el, event; once=false, changed=false, delay=nothing,
           throttle=nothing, from=nothing, target=nothing,
           consume=false, queue=nothing, filter=nothing)
```

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

### Target and swap

```julia
hxtarget!(el, selector)    # data-hx-target (CSS selector, "this", "closest ...", etc.)
hxswap!(el, style; ...)    # data-hx-swap with optional modifiers
hxswapoob!(el, value)      # data-hx-swap-oob
hxselect!(el, selector)    # data-hx-select
hxselectoob!(el, sels)     # data-hx-select-oob
```

`hxswap!` supports the following keyword modifiers: `transition`,
`swap`, `settle`, `ignoreTitle`, `scroll`, `show`, `focusScroll`.

Valid swap styles: `"innerHTML"`, `"outerHTML"`, `"afterbegin"`,
`"beforebegin"`, `"beforeend"`, `"afterend"`, `"delete"`, `"none"`.

```julia
el = HTMLElement(:div)
hxswap!(el, "innerHTML"; transition=true, settle="100ms")
# → data-hx-swap="innerHTML transition:true settle:100ms"
```

### Values and URLs

```julia
hxvals!(el, json)             # data-hx-vals (JSON string)
hxpushurl!(el, value)         # data-hx-push-url ("true"/"false"/URL)
hxreplaceurl!(el, value)      # data-hx-replace-url
```

### User interaction

```julia
hxconfirm!(el, message)       # data-hx-confirm — shows confirm() dialog
hxprompt!(el, message)        # data-hx-prompt — shows prompt() dialog
hxindicator!(el, selector)    # data-hx-indicator
```

### Progressive enhancement and parameters

```julia
hxboost!(el, value)           # data-hx-boost ("true"/"false")
hxinclude!(el, selector)      # data-hx-include
hxparams!(el, value)          # data-hx-params ("*", "none", param list, or "not ...")
hxheaders!(el, json)          # data-hx-headers (JSON string)
hxsync!(el, value)            # data-hx-sync
hxencoding!(el, encoding)     # data-hx-encoding (default: "multipart/form-data")
hxext!(el, extensions)        # data-hx-ext (comma-separated extension names)
```

### Event handling

```julia
hxon!(el, event, script)      # data-hx-on:<event>="<script>"
```

### Disabling and inheritance

```julia
hxdisable!(el)                # data-hx-disable — disables htmx processing
hxdisabledelt!(el, selector)  # data-hx-disabled-elt
hxdisinherit!(el, attrs)      # data-hx-disinherit ("*" or space-separated list)
hxinherit!(el, attrs)         # data-hx-inherit
```

### History and preservation

```julia
hxhistory!(el, value)         # data-hx-history ("false" to prevent caching)
hxhistoryelt!(el)             # data-hx-history-elt
hxpreserve!(el)               # data-hx-preserve (element must have a stable id)
```

### Request configuration and validation

```julia
hxrequestconfig!(el, value)   # data-hx-request (e.g. "timeout:3000, credentials:true")
hxvalidate!(el)               # data-hx-validate — enables HTML5 validation
```

### Chaining example

All htmx helpers return the element, so they can be chained:

```julia
el = HTMLElement(:button)
el |> x -> hxpost!(x, "/submit") |>
     x -> hxtarget!(x, "#result") |>
     x -> hxswap!(x, "outerHTML") |>
     x -> hxconfirm!(x, "Are you sure?")
```

## TODOs

- support CDATA
- support comments
