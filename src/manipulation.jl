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
function setattr!(elem::HTMLElement, name::AbstractString, value::AbstractString)
    elem.attributes[name] = value
end


"""
    getattr(elem::HTMLElement, name::AbstractString) :: Union{AbstractString, Nothing}

Get the value of an attribute of an element.
"""
getattr(elem::HTMLElement, name) = hasattr(elem, name) ? elem.attributes[name] : nothing

"""
    getattr(elem::HTMLElement, name::AbstractString, default::AbstractString) :: AbstractString

Get the value of an attribute of an element, or a default value if the attribute is not present.
"""
getattr(elem::HTMLElement, name, default) = get(elem.attributes, name, default)


"""
    hasattr(elem::HTMLElement, name::AbstractString) :: Bool

Check whether an element has an attribute.
"""
hasattr(elem::HTMLElement, name) = name in keys(attrs(elem))


AbstractTrees.children(elem::HTMLElement) = elem.children
AbstractTrees.children(::HTMLText) = ()

# TODO there is a naming conflict here if you want to use both packages
# (see https://github.com/JuliaWeb/Gumbo.jl/issues/31)
#
# I still think exporting `children` from Gumbo is the right thing to
# do, since it's probably more common to be using this package alone

children = AbstractTrees.children

# indexing into an element indexes into its children

"""
    getindex(elem::HTMLElement, i::Integer) :: Union{HTMLElement, Nothing}

Get the `i`th child of an element.
"""
Base.getindex(elem::HTMLElement, i) = getindex(elem.children, i)

"""
    setindex!(elem::HTMLElement, i::Integer, val::HTMLElement)

Set the `i`th child of an element.
"""
function Base.setindex!(elem::HTMLElement, i, val)
    if val.parent != elem
        val.parent = elem
    end
    setindex!(elem.children, i, val)
end

"""
    push!(elem::HTMLElement, val::HTMLElement)

Push a child onto an element.
"""
function Base.push!(elem::HTMLElement, val)
    if val.parent != elem
        val.parent = elem
    end
    push!(elem.children, val)
end


"""
    findfirst(f::Function, doc::HTMLDocument) :: Union{HTMLElement, Nothing}

Find the first element in `doc` for which `f` is true.
"""
findfirst(f::Function, doc::HTMLDocument)::Union{HTMLElement,Nothing} = findfirst(f, doc.root)

"""
    findfirst(f::Function, elem::HTMLElement) :: Union{HTMLElement, Nothing}

Find the first element in `elem` for which `f` is true.
"""
function findfirst(f::Function, elem::HTMLElement)::Union{HTMLElement,Nothing}
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
getbyid(doc::HTMLDocument, id::AbstractString) = getbyid(doc.root, id)::Union{HTMLElement,Nothing}


"""
    getbyid(elem::HTMLElement, id::AbstractString) :: Union{HTMLElement, Nothing}

Get the element with the given `id` from `elem`.
"""
getbyid(elem::HTMLElement, id::AbstractString) = findfirst(x -> hasattr(x, "id") && getattr(x, "id") == id, elem)::Union{HTMLElement,Nothing}


"""
    applyif!(condition::Function, f!::Function, doc::HTMLDocument)
    
Apply `f!` to all elements (nested included) in `doc` for which `condition` is true.
"""
applyif!(condition::Function, f!::Function, doc::HTMLDocument) = applyif!(condition, f!, doc.root)


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
    hasattr(elem, "class") && cls in split(getattr(elem, "class", ""))
end


"""
    addclass!(elem::HTMLElement, cls::AbstractString)

Adds the class `cls` to `elem`.
"""
function addclass!(elem::HTMLElement, cls::AbstractString)
    if hasattr(elem, "class") && !hasclass(elem, cls)
        setattr!(elem, "class", getattr(elem, "class") * " " * cls)
    else
        setattr!(elem, "class", cls)
    end
end

"""
    removeclass!(elem::HTMLElement, cls::AbstractString)

Removes the class `cls` from `elem`.
"""
function removeclass!(elem::HTMLElement, cls::AbstractString)
    if hasclass(elem, cls)
        setattr!(elem, "class", join(filter(x -> x != cls, split(getattr(elem, "class", ""))), " "))
    end
end

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
            print(io, c.text, ' ')
        end
    end

    return strip(String(take!(io)))
end
