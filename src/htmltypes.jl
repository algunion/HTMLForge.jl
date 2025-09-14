abstract type HTMLNode end

mutable struct HTMLText <: HTMLNode
    parent::HTMLNode
    text::AbstractString
end

# convenience constructor for defining without parent
HTMLText(text::AbstractString) = HTMLText(NullNode(), text)

struct NullNode <: HTMLNode end

mutable struct HTMLElement{T} <: HTMLNode
    children::Vector{HTMLNode}
    parent::HTMLNode
    attributes::Dict{AbstractString, AbstractString}
end

function HTMLElement(T::Symbol)
    HTMLElement{T}(HTMLNode[], NullNode(), Dict{AbstractString, AbstractString}())
end

function HTMLElement(T::Symbol, children::Vector{<:HTMLNode}, parent::HTMLElement,
        attributes::Dict{AbstractString, AbstractString})
    HTMLElement{T}(children, parent, attributes)
end

function HTMLElement(T::Symbol, children::Vector{<:HTMLNode},
        attributes::Dict{AbstractString, AbstractString})
    HTMLElement{T}(children, NullNode(), attributes)
end

function HTMLElement(T::Symbol, child::HTMLNode)
    HTMLElement{T}([child], NullNode(), Dict{AbstractString, AbstractString}())
end

function HTMLElement(
        T::Symbol, child::HTMLNode, attributes::Dict{AbstractString, AbstractString})
    HTMLElement{T}([child], NullNode(), attributes)
end

function HTMLElement(T::Symbol, children::Vector{<:HTMLNode}; kwargs...)
    dictattrs = Dict{AbstractString, AbstractString}()
    for (k, v) in kwargs
        skey = string(k)
        dictattrs[replace(skey, "_" => "-")] = v
    end

    HTMLElement{T}(children, NullNode(), dictattrs)
end

mutable struct HTMLDocument
    doctype::AbstractString
    root::HTMLElement
end

struct InvalidHTMLException <: Exception
    msg::AbstractString
end

struct InvalidAttributeException <: Exception
    msg::AbstractString
end
