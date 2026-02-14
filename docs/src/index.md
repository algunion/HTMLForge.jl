# HTMLForge.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://algunion.github.io/HTMLForge.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://algunion.github.io/HTMLForge.jl/dev/)
[![codecov](https://codecov.io/gh/algunion/HTMLForge.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/algunion/HTMLForge.jl)

**HTMLForge.jl** is a Julia wrapper around the [Gumbo library](https://codeberg.org/gumbo-parser/gumbo-parser) for parsing HTML, with first-class support for [HTMX](https://htmx.org/) attributes.

HTMLForge is a fork of the Gumbo.jl project, extended with HTMX types, functions, and syntax sugar for building interactive web UIs from Julia.

## Features

- **Full HTML parsing** via Gumbo — handles real-world, messy HTML gracefully
- **Rich type system** — `HTMLDocument`, `HTMLElement{T}`, `HTMLText`, `NullNode`
- **Tree traversal** — pre-order, post-order, breadth-first iterators
- **Element manipulation** — find, modify, add/remove CSS classes
- **HTMX first-class support** — 30+ typed helpers for every htmx attribute
- **Experimental HTMX DSL** — macro and pipe-based interfaces that compress 625 LOC into <100

## Quick Example

```julia
using HTMLForge

# Parse HTML
doc = parsehtml("<h1>Hello, world!</h1>")

# Create elements with HTMX
el = HTMLElement(:button)
hxpost!(el, "/api/submit")
hxtarget!(el, "#result")
hxswap!(el, "outerHTML")
hxconfirm!(el, "Are you sure?")
```

## Installation

```julia
using Pkg
Pkg.add("HTMLForge")
```

Or in Pkg mode (`]`):

```
add HTMLForge
```
