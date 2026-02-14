# Parsing

## Full Document Parsing

`parsehtml(html_string; strict=false, preserve_whitespace=false, preserve_template=false, include_parent=true)`

The workhorse function. Takes a valid UTF-8 string and returns an `HTMLDocument`:

```julia
doc = parsehtml("<h1>Hello, world!</h1>")
```

### Keyword arguments

| Keyword               | Type   | Default | Description                                      |
| --------------------- | ------ | ------- | ------------------------------------------------ |
| `strict`              | `Bool` | `false` | Throw `InvalidHTMLException` on parse errors     |
| `preserve_whitespace` | `Bool` | `false` | Keep whitespace text nodes (e.g. inside `<pre>`) |
| `preserve_template`   | `Bool` | `false` | Preserve `<template>` elements in the tree       |
| `include_parent`      | `Bool` | `true`  | Set parent references on child nodes             |

HTMLForge is a very permissive parser — it will produce valid HTML for *any* input. If you want strict validation, use `strict=true`.

## Snippet Parsing

`parsehtml_snippet(html_string; preserve_whitespace=false, preserve_template=false)`

Parses an HTML fragment (not a full document) and returns an `HTMLElement`:

```julia
el = parsehtml_snippet("<p>Hello</p>")
```

If the snippet contains multiple top-level tags, they are wrapped in a `<div>`:

```julia
el = parsehtml_snippet("<p>A</p><p>B</p>")
# → HTMLElement{:div} with two <p> children
```

Accepts the same `preserve_whitespace` and `preserve_template` keyword arguments as `parsehtml`.
