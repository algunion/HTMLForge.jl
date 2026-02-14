# Manipulation

## Accessing Element Properties

- `tag(elem)` — get the tag of an element as a symbol
- `attrs(elem)` — return the attributes dict
- `getattr(elem, name[, default])` — get attribute value or `nothing`/`default`
- `setattr!(elem, name, value)` — set attribute (validated)
- `hasattr(elem, name)` — check whether an attribute exists

## Children and Text

- `children(elem)` — return the children array
- `text(elem)` — recursively extract all text content

## Finding Elements

- `findfirst(f, elem)` / `findfirst(f, doc)` — find the first element (pre-order DFS) matching predicate `f`
- `getbyid(elem, id)` / `getbyid(doc, id)` — find element by `id` attribute
- `applyif!(condition, f!, elem)` — apply a mutating function to all matching elements

### Examples

```julia
# Find the first <a> tag
findfirst(x -> tag(x) == :a, doc.root)

# Find element by id
getbyid(doc, "main-content")

# Apply a function to all matching elements
applyif!(x -> tag(x) == :div, x -> setattr!(x, "class", "wide"), doc)
```

## CSS Class Helpers

- `hasclass(elem, cls)` — check if element has a CSS class
- `addclass!(elem, cls)` — add a CSS class (no-op if already present)
- `removeclass!(elem, cls)` — remove a CSS class
- `replaceclass!(elem, old, new)` — replace one class with another; pass `nothing` to remove

### Examples

```julia
el = HTMLElement(:div)
addclass!(el, "active")
addclass!(el, "highlight")
hasclass(el, "active")       # true
replaceclass!(el, "active", "inactive")
removeclass!(el, "highlight")
```

## Validation

Attribute names and CSS class values are validated automatically when using `setattr!`, `addclass!`, `replaceclass!`, and bracket assignment.

Invalid attribute names raise `InvalidAttributeException`. Invalid class values raise `ArgumentError` or `InvalidAttributeException`.

Use the `@validate` macro directly:

```julia
@validate :attr "data-value"          # validate attribute name
@validate :class "my-class"           # validate class name
@validate :attr ["id", "data-value"]  # validate multiple names
@validate :class ["cls1", "cls2"]     # validate multiple classes
```

## Pretty Printing

`prettyprint(elem)` / `prettyprint(io, elem)` — output nicely indented HTML:

```julia
prettyprint(doc)              # print document to stdout
prettyprint(io, doc)          # print to IO stream
prettyprint(elem)             # print element
```
