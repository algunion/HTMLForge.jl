# tests of basic utilities for working with HTML

import HTMLForge: HTMLNode, NullNode, findfirst

# convenience constructor works
@test HTMLElement(:body) == HTMLElement{:body}(HTMLNode[],
    NullNode(),
    Dict{AbstractString,AbstractString}())

# accessing tags works
@test HTMLElement(:body) |> tag == :body

let
    elem = HTMLElement{:body}(HTMLNode[], NullNode(), Dict("foo" => "bar"))
    @test getattr(elem, "foo") == "bar"
    @test getattr(elem, "foo", "baz") == "bar"
    @test getattr(elem, "bar", "qux") == "qux"
end

@testset "HTML manipulation" begin
    doc = open("$testdir/fixtures/attrs_test.html") do attrstest
        read(attrstest, String) |> parsehtml
    end
    @test doc.root |> tag == :HTML
    @test findfirst(x -> hasattr(x, "id") && getattr(x, "id") == "myid", doc.root) |> tag == :p
    @test getbyid(doc.root, "myid") |> tag == :p
    applyif!(x -> x |> tag == :div, x -> setattr!(x, "class", "wide"), doc.root)
    @test findfirst(x -> hasattr(x, "class") && getattr(x, "class") == "wide", doc.root) |> tag == :div
    println(doc)
    @test hasclass(getbyid(doc.root, "adiv"), "wide")
    @test !hasclass(doc.root, "narrow")
    addclass!(doc.root, "narrow")
    @test hasclass(doc.root, "narrow")
    removeclass!(doc.root, "narrow")
    @test !hasclass(doc.root, "narrow")
end