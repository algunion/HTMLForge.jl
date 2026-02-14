
# test for comparisons and hashing

@testset "HTMLText equality and hashing" begin
    x = HTMLText("test")
    y = HTMLText("test")
    x1 = HTMLText("test1")
    @test x == y
    @test hash(x) == hash(y)
    @test x1 != y
    @test hash(x1) != hash(y)
    @test isequal(x, y)
    @test !isequal(x, x1)
end

@testset "HTMLElement equality and hashing" begin
    x = HTMLElement(:div)
    y = HTMLElement(:div)
    @test x == y
    @test hash(x) == hash(y)
    push!(x, HTMLElement(:p))
    @test x != y
    @test hash(x) != hash(y)
    push!(y, HTMLElement(:p))
    @test x == y
    @test hash(x) == hash(y)
    setattr!(x, "class", "test")
    @test x != y
    @test hash(x) != hash(y)
    setattr!(y, "class", "test")
    @test x == y
    @test hash(x) == hash(y)
end

@testset "HTMLElement tag comparison" begin
    # Elements with different tags should not be equal, even with same attrs/children
    div_el = HTMLElement(:div)
    span_el = HTMLElement(:span)
    @test div_el != span_el
    @test hash(div_el) != hash(span_el)
    @test !isequal(div_el, span_el)

    # Same tag, different attrs
    d1 = HTMLElement(:div)
    d2 = HTMLElement(:div)
    setattr!(d1, "id", "a")
    @test d1 != d2

    # Same tag, same attrs, different children
    d3 = HTMLElement(:div)
    d4 = HTMLElement(:div)
    push!(d3, HTMLText("hello"))
    @test d3 != d4
end

@testset "HTMLDocument equality and hashing" begin
    x = HTMLDocument("html", HTMLElement(:html))
    y = HTMLDocument("html", HTMLElement(:html))
    @test x == y
    @test hash(x) == hash(y)
    @test isequal(x, y)
    x.doctype = ""
    @test x != y
    @test hash(x) != hash(y)
    @test !isequal(x, y)
    y.doctype = ""
    @test x == y
    @test hash(x) == hash(y)
end

@testset "NullNode equality and hashing" begin
    n1 = NullNode()
    n2 = NullNode()
    @test isequal(n1, n2)
    @test hash(n1) == hash(n2)
end

@testset "hash consistency with ==" begin
    # The contract: x == y implies hash(x) == hash(y)
    pairs = [
        (HTMLText("a"), HTMLText("a")),
        (HTMLElement(:div), HTMLElement(:div)),
        (HTMLDocument("html", HTMLElement(:html)),
            HTMLDocument("html", HTMLElement(:html))),
        (NullNode(), NullNode())
    ]
    for (a, b) in pairs
        @test a == b
        @test hash(a) == hash(b)
    end

    # Different types/values should differ
    @test HTMLElement(:div) != HTMLElement(:span)
    @test hash(HTMLElement(:div)) != hash(HTMLElement(:span))
end
