# Tree Traversal

HTMLForge re-exports convenience aliases for common tree traversal strategies from [AbstractTrees.jl](https://github.com/Keno/AbstractTrees.jl/).

- `preorder(node)` — pre-order depth-first traversal
- `postorder(node)` — post-order depth-first traversal
- `breadthfirst(node)` — breadth-first (level-order) traversal

## Example

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
""")

for elem in preorder(doc.root)
    println(tag(elem))
end
# HTML, head, body, div, p, a, p, div, span

for elem in postorder(doc.root)
    println(tag(elem))
end
# head, p, a, p, div, span, div, body, HTML

for elem in breadthfirst(doc.root)
    println(tag(elem))
end
# HTML, head, body, div, div, p, a, p, span
```

You can also use the iterators from AbstractTrees.jl directly (`PreOrderDFS`, `PostOrderDFS`, `StatelessBFS`).

## Comparison and Equality

`HTMLDocument`, `HTMLElement`, and `HTMLText` all support `==`, `isequal`, and `hash`. Two elements are considered equal if they have the same tag, attributes, and children (parents are ignored):

```julia
HTMLElement(:div) == HTMLElement(:div)  # true
```
