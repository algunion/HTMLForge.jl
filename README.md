# HTMLForge.jl

[![version](https://juliahub.com/docs/HTMLForge/version.svg)](https://juliahub.com/ui/Packages/HTMLForge/mllB2) [![Build Status](https://travis-ci.org/JuliaWeb/HTMLForge.jl.svg?branch=master)](https://travis-ci.org/JuliaWeb/HTMLForge.jl) [![codecov.io](http://codecov.io/github/JuliaWeb/HTMLForge.jl/coverage.svg?branch=master)](http://codecov.io/github/JuliaWeb/HTMLForge.jl?branch=master) [![pkgeval](https://juliahub.com/docs/HTMLForge/pkgeval.svg)](https://juliahub.com/ui/Packages/HTMLForge/mllB2) [![deps](https://juliahub.com/docs/HTMLForge/deps.svg)](https://juliahub.com/ui/Packages/HTMLForge/mllB2?t=2)

HTMLForge.jl is a Julia wrapper around
[Google's Gumbo library](https://github.com/google/gumbo-parser) for
parsing HTML.

### Important Note
HTMLForge is a continuation of the Gumbo.jl project, which was a Julia wrapper around the Gumbo C library. C Gumbo is no longer maintained, and HTMLForge is a fork of Gumbo.jl with the aim of maintaining the API of the original package while slowly removing C Gumbo dependency. If you were using Gumbo.jl, you should be able to switch to HTMLForge.jl with no changes to your code.

The long term plan is to make HTMLForge a pure Julia library, but for now it is a wrapper around the C library. Alternatively, we can consider switching to a different C/Rust library that is still maintained.

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

```
add HTMLForge
```

## Basic usage

The workhorse is the `parsehtml` function, which takes a single
argument, a valid UTF8 string, which is interpreted as HTML data to be
parsed, e.g.:

```julia
parsehtml("<h1> Hello, world! </h1>")
```

Parsing an HTML file named `filename`can be done using:

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
`strict` which, if `true`, causes an `InvalidHTMLError` to be thrown
if the call to the HTMLForge C library produces any errors.

## HTML types

This library defines a number of types for representing HTML.

### `HTMLDocument`

`HTMlDocument` is what is returned from a call to `parsehtml` it has a
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
    attributes::Dict{String, String}
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

`HTMLElement`s have a `parent` field, which refers to another
`HTMLNode`. `parent` will always be an `HTMLElement`, unless the
element has no parent (as is the case with the root of a document), in
which case it will be a `NullNode`, a special type of `HTMLNode` which
exists for just this purpose. Empty `HTMLElement`s constructed as in
the example above will also have a `NullNode` for a parent.

`HTMLElement`s also have `children`, which is a vector of
`HTMLElement` containing the children of this element, and
`attributes`, which is a `Dict` mapping attribute names to values.

`HTMLElement`s implement `getindex`, `setindex!`, and `push!`;
indexing into or pushing onto an `HTMLElement` operates on its
children array.

There are a number of convenience methods for working with `HTMLElement`s:

- `tag(elem)`
  get the tag of this element as a symbol

- `attrs(elem)`
  return the attributes dict of this element

- `children(elem)`
   return the children array of this element

- `getattr(elem, name)`
  get the value of attribute `name` or raise a `KeyError`. Also
  supports being called with a default value (`getattr(elem, name,
  default)`) or function (`getattr(f, elem, name)`).

- `setattr!(elem, name, value)`
  set the value of attribute `name` to `value`

### `HTMLText`

```jl
type HTMLText <: HTMLNode
    parent::HTMLNode
    text::String
end
```

Represents text appearing in an HTML document. For example:

```julia
julia> doc = parsehtml("<h1> Hello, world! </h1>")
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

julia> doc.root[2][1][1]
HTML Text:  Hello, world!
```

This type is quite simple, just a reference to its parent and the
actual text it represents (this is also accessible by a `text`
function). You can construct `HTMLText` instances as follows:

```jl
julia> HTMLText("Example text")
HTML Text: Example text
```

Just as with `HTMLElement`s, the parent of an instance so constructed
will be a `NullNode`.


## Tree traversal

Use the iterators defined in
[AbstractTrees.jl](https://github.com/Keno/AbstractTrees.jl/), e.g.:

```julia
julia> using AbstractTrees

julia> using HTMLForge

julia> doc = parsehtml("""
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

julia> for elem in PreOrderDFS(doc.root) println(tag(elem)) end
HTML
head
body
div
p
a
p
div
span

julia> for elem in PostOrderDFS(doc.root) println(tag(elem)) end
head
p
a
p
div
span
div
body
HTML

julia> for elem in StatelessBFS(doc.root) println(tag(elem)) end
HTML
head
body
div
div
p
a
p
span

julia>
```

## TODOS

- support CDATA
- support comments
