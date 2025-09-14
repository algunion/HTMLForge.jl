using Test
import HTMLForge: HTMLNode, NullNode, HTMLElement

# Test for HTMLElement(T::Symbol)
@test HTMLElement(:body) ==
      HTMLElement{:body}(HTMLNode[], NullNode(), Dict{AbstractString, AbstractString}())

# Test for HTMLElement(T::Symbol, children::Vector{HTMLNode}, attributes::Dict{AbstractString,AbstractString})
children = [HTMLElement(:div), HTMLElement(:span)]
attributes = Dict{AbstractString, AbstractString}("class" => "container")
@test HTMLElement(:div, children, attributes) ==
      HTMLElement{:div}(children, NullNode(), attributes)

# Test for HTMLElement(T::Symbol, child::HTMLNode)
child = HTMLElement(:div)
@test HTMLElement(:span, child) ==
      HTMLElement{:span}([child], NullNode(), Dict{AbstractString, AbstractString}())

# Test for HTMLElement(T::Symbol, child::HTMLNode, attributes::Dict{AbstractString,AbstractString})
attributes = Dict{AbstractString, AbstractString}("id" => "unique")
@test HTMLElement(:span, child, attributes) ==
      HTMLElement{:span}([child], NullNode(), attributes)

# Test for HTMLElement(T::Symbol, children::Vector{HTMLNode}; kwargs...)
kwargs = (:style => "color: red;", :class => "test", :data_test => "test")
@test HTMLElement(:ul, children; kwargs...) == HTMLElement{:ul}(children, NullNode(),
    Dict("style" => "color: red;", "class" => "test", "data-test" => "test"))

# accessing tags works
@test HTMLElement(:body) |> tag == :body

let
    elem = HTMLElement{:body}(HTMLNode[], NullNode(), Dict("foo" => "bar"))
    @test getattr(elem, "foo") == "bar"
    @test getattr(elem, "foo", "baz") == "bar"
    @test getattr(elem, "bar", "qux") == "qux"
end
