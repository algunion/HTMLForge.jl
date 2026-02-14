# functions for accessing and manipulation HTML types

import AbstractTrees
# elements

"""
    tag(elem::HTMLElement)

Get the tag of an element.
"""
tag(::HTMLElement{T}) where {T} = T

"""
    attrs(elem::HTMLElement) :: Dict{String, String}

Get the attributes of an element.
"""
attrs(elem::HTMLElement) = elem.attributes

"""
    setattrs!(elem::HTMLElement, name::AbstractString, value::AbstractString)

Set the attributes of an element.
"""
function setattr!(
        elem::HTMLElement, name::Union{AbstractString, Symbol}, value::AbstractString)
    attr_str = string(name)
    @validate :attr attr_str
    elem.attributes[attr_str] = value
end

"""
    getattr(elem::HTMLElement, name::AbstractString, default=nothing) :: Union{String, Nothing}

Get the value of an attribute of an element or `default` if not present.
"""
function getattr end
function getattr(elem::HTMLElement, name::Union{AbstractString, Symbol}, default = nothing)
    get(
        elem.attributes, string(name), default)
end

"""
    hasattr(elem::HTMLElement, name::AbstractString) :: Bool

Check whether an element has an attribute.
"""
hasattr(elem::HTMLElement, name::Union{AbstractString, Symbol}) = string(name) in keys(attrs(elem))

AbstractTrees.children(elem::HTMLElement) = Base.getfield(elem, :children)
AbstractTrees.children(::HTMLText) = ()

# TODO there is a naming conflict here if you want to use both packages
# (see https://github.com/JuliaWeb/Gumbo.jl/issues/31)
#
# I still think exporting `children` from Gumbo is the right thing to
# do, since it's probably more common to be using this package alone

children = AbstractTrees.children

"""
    length(elem::HTMLElement)

Get the `length` of `elem`'s children.
"""
Base.length(elem::HTMLElement) = length(children(elem))

"""
    length:text::HTMLText)

Get the `length` of text content.
"""
Base.length(text::HTMLText) = length(text.text)

# indexing into an element indexes into its children
# key based indexing into attributes

"""
    getindex(elem::HTMLElement, i::Int)

Get the `i`th child of an element.
"""
Base.getindex(elem::HTMLElement, i::Int) = getindex(elem.children, i)

"""
    getindex(elem::HTMLElement, key::Union{AbstractString, Symbol})

Get the attribute with the given `key` from an element.
"""
Base.getindex(elem::HTMLElement, key::AbstractString) = getindex(elem.attributes, key)
Base.getindex(elem::HTMLElement, key::Symbol) = getindex(elem.attributes, string(key))

"""
    setindex!(elem::HTMLElement, val::HTMLElement, i::Integer)

Set the `i`th child of an element.
"""
function Base.setindex!(elem::HTMLElement, val::HTMLNode, i)
    if val.parent != elem
        val.parent = elem
    end
    setindex!(children(elem), val, i)
end

"""
    setindex!(elem::HTMLElement, val::AbstractString, key::Union{AbstractString, Symbol})

Set the attribute with the given `key` on an element.
"""
function Base.setindex!(
        elem::HTMLElement, val::AbstractString, key::Union{AbstractString, Symbol})
    @validate :attr string(key)
    elem.attributes[string(key)] = val
end

Base.firstindex(elem::HTMLElement) = firstindex(children(elem))
Base.lastindex(elem::HTMLElement) = lastindex(children(elem))

"""
    push!(elem::HTMLElement, val::HTMLElement)

Push a child onto an element.
"""
function Base.push!(elem::HTMLElement, val::HTMLNode)
    if val.parent != elem
        val.parent = elem
    end
    push!(elem.children, val)
end

"""
    findfirst(f::Function, doc::HTMLDocument) :: Union{HTMLElement, Nothing}

Find the first (PreOrderDFS) element in `doc` for which `f` is true.
"""
findfirst(f::Function, doc::HTMLDocument)::Union{HTMLElement, Nothing} = findfirst(
    f, doc.root)

"""
    findfirst(f::Function, elem::HTMLElement) :: Union{HTMLElement, Nothing}

Find the first (PreOrderDFS) element in `elem` for which `f` is true.
"""
function findfirst(f::Function, elem::HTMLElement)::Union{HTMLElement, Nothing}
    for el in AbstractTrees.PreOrderDFS(elem)
        el isa HTMLElement && f(el) && return el
    end
    return nothing
end

# more utility functions

"""
    getbyid(doc::HTMLDocument, id::AbstractString) :: Union{HTMLElement, Nothing}

Get the element with the given `id` from `doc`.
"""
getbyid(doc::HTMLDocument, id::AbstractString) = getbyid(
    doc.root, id)::Union{HTMLElement, Nothing}

"""
    getbyid(elem::HTMLElement, id::AbstractString) :: Union{HTMLElement, Nothing}

Get the element with the given `id` from `elem`.
"""
getbyid(elem::HTMLElement, id::AbstractString) = findfirst(
    x -> hasattr(x, "id") && getattr(x, "id") == id, elem)::Union{HTMLElement, Nothing}

"""
    applyif!(condition::Function, f!::Function, doc::HTMLDocument)
    
Apply `f!` to all elements (nested included) in `doc` for which `condition` is true.
"""
applyif!(condition::Function, f!::Function, doc::HTMLDocument) = applyif!(
    condition, f!, doc.root)

"""
    applyif!(condition::Function, f!::Function, elem::HTMLElement)

Apply `f!` to all elements (nested included) in `elem` for which `condition` is true.
"""
function applyif!(condition::Function, f!::Function, elem::HTMLElement)
    for el in AbstractTrees.PreOrderDFS(elem)
        el isa HTMLElement && condition(el) && f!(el)
    end
end

"""
    hasclass(elem::HTMLElement, cls::AbstractString)

Returns `true` if `elem` has the class `cls`.
"""
function hasclass(elem::HTMLElement, cls::AbstractString)::Bool
    stripped_cls = strip(cls)
    isempty(stripped_cls) &&
        throw(ArgumentError("Class name cannot be empty or whitespace."))
    hasattr(elem, "class") && stripped_cls ∈ split(getattr(elem, "class"))
end

"""
    addclass!(elem::HTMLElement, cls::AbstractString)

Adds the class `cls` to `elem`.
"""
function addclass!(elem::HTMLElement, cls::AbstractString)
    @validate :class cls
    stripped_cls = strip(cls)
    isempty(stripped_cls) &&
        throw(ArgumentError("Class name cannot be empty or whitespace."))
    if !hasattr(elem, "class")
        setattr!(elem, "class", stripped_cls)
    elseif !hasclass(elem, stripped_cls)
        setattr!(elem, "class", getattr(elem, "class") * " " * stripped_cls)
    end
    return elem
end

function replaceclass!(
        elem::HTMLElement, oldclass::AbstractString, newclass::Union{
            AbstractString, Nothing})
    if !isnothing(newclass)
        @validate :class newclass
    end

    if hasclass(elem, oldclass)
        classes = split(getattr(elem, "class"))
        idx = Base.findfirst(==(oldclass), classes)
        if !isnothing(newclass)
            classes[idx] = strip(newclass)
        else
            deleteat!(classes, idx)
        end
        if isempty(classes)
            delete!(elem.attributes, "class")
        else
            elem[:class] = join(classes, " ")
        end
    end
    return elem
end

"""
    removeclass!(elem::HTMLElement, cls::AbstractString)

Removes the class `cls` from `elem`.
"""
removeclass!(elem::HTMLElement, cls::AbstractString) = replaceclass!(elem, cls, nothing)

function _firsttag(el::HTMLElement, t)
    findfirst(x -> tag(x) === t, el)
end

# body
body(el::HTMLElement)::Union{HTMLElement, Nothing} = _firsttag(el, :body)
body(doc::HTMLDocument)::Union{HTMLElement, Nothing} = body(doc.root)

#head
head(el::HTMLElement)::Union{HTMLElement, Nothing} = _firsttag(el, :head)
head(doc::HTMLDocument)::Union{HTMLElement, Nothing} = head(doc.root)

# text

"""
    text(t::HTMLText) :: AbstractString

Get the text of a text element.
"""
text(t::HTMLText) = t.text

"""
    text(el::HTMLElement) :: AbstractString

Get the text of an element.
"""
function text(el::HTMLElement)
    io = IOBuffer()
    for c in AbstractTrees.PreOrderDFS(el)
        if c isa HTMLText
            print(io, text(c), ' ')
        end
    end

    return strip(String(take!(io)))
end

# Traversal convenience aliases

"""
    postorder(node)

Return a post-order depth-first iterator over the tree rooted at `node`.
"""
postorder(node) = AbstractTrees.PostOrderDFS(node)

"""
    preorder(node)

Return a pre-order depth-first iterator over the tree rooted at `node`.
"""
preorder(node) = AbstractTrees.PreOrderDFS(node)

"""
    breadthfirst(node)

Return a breadth-first iterator over the tree rooted at `node`.
"""
breadthfirst(node) = AbstractTrees.StatelessBFS(node)
