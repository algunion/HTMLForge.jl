# HTML Types

HTMLForge defines a type hierarchy for representing HTML documents.

## Type Hierarchy

```
HTMLNode (abstract)
├── HTMLElement{T}   — an element with tag T (e.g. HTMLElement{:div})
├── HTMLText         — text content
└── NullNode         — sentinel for missing parents
```

## HTMLDocument

Returned by `parsehtml`. Has two fields:

- `doctype::AbstractString` — the doctype of the parsed document (empty string if none)
- `root::HTMLElement` — the root element of the document tree

```julia
doc = parsehtml("<html><body><p>Hi</p></body></html>")
doc.doctype  # ""
doc.root     # HTMLElement{:HTML}
```

## HTMLElement{T}

The core type, parametrized by a `Symbol` representing its tag:

```julia
mutable struct HTMLElement{T} <: HTMLNode
    children::Vector{HTMLNode}
    parent::HTMLNode
    attributes::Dict{AbstractString, AbstractString}
end
```

### Constructors

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

### Indexing

`HTMLElement` supports both integer indexing (children) and string/symbol indexing (attributes):

```julia
el = HTMLElement(:div)
el["class"] = "wide"   # set attribute
el[:class]             # get attribute → "wide"
el[1]                  # first child
```

## HTMLText

Represents text content within an HTML document:

```julia
mutable struct HTMLText <: HTMLNode
    parent::HTMLNode
    text::AbstractString
end
```

```julia
HTMLText("Example text")
```

Constructed text nodes have a `NullNode` parent by default.

## NullNode

A sentinel type used as the parent of root elements and detached nodes:

```julia
struct NullNode <: HTMLNode end
```
