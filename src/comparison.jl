# comparison functions for HTML Nodes and Documents

# TODO right now hashing and equality completely ignore
# parents. I think this is *probably* appropriate but it deserves
# some more thought. There's an argument that two HTMLElements with
# the same contents and children but different parent pointers are not
# really equal. Perhaps an auxilliary equality function could be provided
# for this purpose?

# equality

import Base: ==, isequal, hash

isequal(x::NullNode, y::NullNode) = true

function isequal(x::HTMLDocument, y::HTMLDocument)
    isequal(x.doctype, y.doctype) && isequal(x.root, y.root)
end

isequal(x::HTMLText, y::HTMLText) = isequal(x.text, y.text)

function isequal(x::HTMLElement, y::HTMLElement)
    isequal(x.attributes, y.attributes) && isequal(x.children, y.children)
end

==(x::HTMLDocument, y::HTMLDocument) = ==(x.doctype, y.doctype) && ==(x.root, y.root)

==(x::HTMLText, y::HTMLText) = ==(x.text, y.text)

function ==(x::HTMLElement, y::HTMLElement)
    ==(x.attributes, y.attributes) && ==(x.children, y.children)
end

# hashing

function hash(doc::HTMLDocument)
    hash(hash(HTMLDocument), hash(hash(doc.doctype), hash(doc.root)))
end

function hash(elem::HTMLElement{T}) where {T}
    h = hash(HTMLElement)
    h = hash(h, hash(T))
    h = hash(h, hash(attrs(elem)))
    for child in children(elem)
        h = hash(h, hash(child))
    end
    return h
end

hash(t::HTMLText) = hash(hash(HTMLText), hash(t.text))
hash(n::NullNode) = hash(NullNode)
