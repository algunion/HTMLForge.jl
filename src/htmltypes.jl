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
    attributes::Dict{AbstractString,AbstractString}
end

# convenience constructor for defining an empty element
HTMLElement(T::Symbol) = HTMLElement{T}(HTMLNode[], NullNode(), Dict{AbstractString,AbstractString}())


HTMLElement(T::Symbol, children::Vector{<:HTMLNode}, attributes::Dict{AbstractString,AbstractString}) = HTMLElement{T}(children, NullNode(), attributes)
HTMLElement(T::Symbol, child::HTMLNode) = HTMLElement{T}([child], NullNode(), Dict{AbstractString,AbstractString}())
HTMLElement(T::Symbol, child::HTMLNode, attributes::Dict{AbstractString,AbstractString}) = HTMLElement{T}([child], NullNode(), attributes)
function HTMLElement(T::Symbol, children::Vector{<:HTMLNode}; kwargs...)
    dictattrs = Dict{AbstractString,AbstractString}()
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


