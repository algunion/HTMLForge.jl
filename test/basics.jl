using Test
import HTMLForge: HTMLNode, NullNode, HTMLElement, HTMLText, HTMLDocument,
                  InvalidHTMLException, InvalidAttributeException

@testset "HTMLElement constructors" begin
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

    # Test with parent
    parent = HTMLElement(:div)
    child = HTMLElement(:p)
    attrs = Dict{AbstractString, AbstractString}("id" => "c1")
    el = HTMLElement(:span, [child], parent, attrs)
    @test tag(el) == :span
end

@testset "tag accessor" begin
    @test HTMLElement(:body) |> tag == :body
    @test HTMLElement(:div) |> tag == :div
    @test HTMLElement(:p) |> tag == :p
end

@testset "getattr" begin
    elem = HTMLElement{:body}(HTMLNode[], NullNode(), Dict("foo" => "bar"))
    @test getattr(elem, "foo") == "bar"
    @test getattr(elem, "foo", "baz") == "bar"
    @test getattr(elem, "bar", "qux") == "qux"
    @test getattr(elem, "missing") === nothing
end

@testset "HTMLText constructors" begin
    t1 = HTMLText("hello")
    @test t1.text == "hello"
    @test t1.parent isa NullNode

    parent = HTMLElement(:p)
    t2 = HTMLText(parent, "world")
    @test t2.text == "world"
    @test t2.parent === parent
end

@testset "HTMLDocument" begin
    root = HTMLElement(:html)
    doc = HTMLDocument("html", root)
    @test doc.doctype == "html"
    @test doc.root === root
end

@testset "NullNode" begin
    n = NullNode()
    @test n isa HTMLNode
    @test n isa NullNode
end

@testset "InvalidHTMLException" begin
    ex = InvalidHTMLException("test error")
    @test ex.msg == "test error"
    @test ex isa Exception
end

@testset "InvalidAttributeException" begin
    ex = InvalidAttributeException("bad attr")
    @test ex.msg == "bad attr"
    @test ex isa Exception
end

@testset "validation" begin
    # Valid attribute names
    @test (@validate :attr "class") == true
    @test (@validate :attr "data-value") == true
    @test (@validate :attr "id") == true

    # Invalid attribute names
    @test_throws ArgumentError @validate :attr ""
    @test_throws InvalidAttributeException @validate :attr "a b"
    @test_throws InvalidAttributeException @validate :attr "a>b"
    @test_throws InvalidAttributeException @validate :attr "a=b"
    @test_throws InvalidAttributeException @validate :attr "a\"b"
    @test_throws InvalidAttributeException @validate :attr "a'b"
    @test_throws InvalidAttributeException @validate :attr "a/b"

    # Vector of attribute names
    @test (@validate :attr ["class", "id"]) == true
    @test_throws ArgumentError @validate :attr ["", "id"]

    # Valid class names
    @test (@validate :class "myclass") == true
    @test (@validate :class "my-class") == true

    # Invalid class names
    @test_throws ArgumentError @validate :class ""
    @test_throws ArgumentError @validate :class "   "
    @test_throws InvalidAttributeException @validate :class "a b"

    # Vector of class names
    @test (@validate :class ["cls1", "cls2"]) == true
    @test_throws InvalidAttributeException @validate :class ["a b", "cls2"]
end

@testset "attributevalidation direct" begin
    import HTMLForge: attributevalidation

    # NULL character
    @test_throws InvalidAttributeException attributevalidation("foo\0bar")

    # Control characters (e.g., \x01, \x7f)
    @test_throws InvalidAttributeException attributevalidation("foo\x01bar")
    @test_throws InvalidAttributeException attributevalidation("\x7f")

    # Valid attribute returns true
    @test attributevalidation("data-value") == true
    @test attributevalidation("x") == true
end

@testset "classvaluevalidation direct" begin
    import HTMLForge: classvaluevalidation

    # Valid class names
    @test classvaluevalidation("my-class") == true
    @test classvaluevalidation("  padded  ") == true  # stripped, non-empty

    # Empty / whitespace-only
    @test_throws ArgumentError classvaluevalidation("")
    @test_throws ArgumentError classvaluevalidation("   ")

    # Whitespace inside
    @test_throws InvalidAttributeException classvaluevalidation("a b")
end
