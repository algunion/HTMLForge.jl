# Getting Started

## Installation

```julia
using Pkg
Pkg.add("HTMLForge")
```

Or activate Pkg mode in the REPL by typing `]`:

```
add HTMLForge
```

## Parsing your first document

```julia
using HTMLForge

doc = parsehtml("<h1> Hello, world! </h1>")
```

This returns an `HTMLDocument` with a `doctype` field and a `root` field pointing to the root `HTMLElement`.

## Parsing a file

```julia
doc = parsehtml(read("myfile.html", String))
```

## Parsing a snippet

Use `parsehtml_snippet` for HTML fragments (not full documents):

```julia
el = parsehtml_snippet("<p>Hello</p>")
```

If the snippet has multiple top-level tags, they are automatically wrapped in a `<div>`.

## Creating elements from scratch

```julia
el = HTMLElement(:div)
el["class"] = "container"

child = HTMLElement(:p, HTMLText("Hello!"))
push!(el, child)

prettyprint(el)
```

## Adding HTMX attributes

All HTMX helpers mutate in place and return the element for chaining:

```julia
btn = HTMLElement(:button)
hxpost!(btn, "/api/submit")
hxtarget!(btn, "#result")
hxswap!(btn, "outerHTML")
```

See the [HTMX Support](@ref) and [Experimental HTMX](@ref) sections for the full API.
