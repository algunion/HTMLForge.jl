@testset "HTML manipulation" begin
    doc = open("$testdir/fixtures/attrs_test.html") do attrstest
        read(attrstest, String) |> parsehtml
    end
    @test doc.root |> tag == :HTML
    @test length(doc.root[2]) == 5
    @test length(doc.root[2][1][1]) == 26
    @test HTMLForge.findfirst(
        x -> hasattr(x, "id") && getattr(x, "id") == "myid", doc.root) |> tag == :p
    @test getbyid(doc.root, "myid") |> tag == :p
    applyif!(x -> x |> tag == :div, x -> setattr!(x, "class", "wide"), doc.root)
    @test HTMLForge.findfirst(
        x -> hasattr(x, "class") && getattr(x, "class") == "wide", doc.root) |> tag == :div
    println(doc)
    @test hasclass(getbyid(doc.root, "adiv"), "wide")
    @test !hasclass(doc.root, "narrow")
    addclass!(doc.root, "narrow")
    @test hasclass(doc.root, "narrow")
    removeclass!(doc.root, "narrow")
    @test !hasclass(doc.root, "narrow")
    addclass!(doc.root, "narrow")
    addclass!(doc.root, "another")
    replaceclass!(doc.root, "narrow", "wide")
    @test hasclass(doc.root, "wide")
end

@testset "addclass! edge cases" begin
    # Adding duplicate class should not alter existing classes
    el = HTMLElement(:div)
    addclass!(el, "foo")
    addclass!(el, "bar")
    @test getattr(el, "class") == "foo bar"
    addclass!(el, "foo")  # duplicate - should be no-op
    @test getattr(el, "class") == "foo bar"

    # Adding to element without class attribute
    el2 = HTMLElement(:span)
    addclass!(el2, "myclass")
    @test getattr(el2, "class") == "myclass"

    # Empty class throws
    el3 = HTMLElement(:div)
    @test_throws ArgumentError addclass!(el3, "")
    @test_throws ArgumentError addclass!(el3, "   ")

    # Returns the element
    el4 = HTMLElement(:div)
    result = addclass!(el4, "cls")
    @test result === el4
end

@testset "hasclass edge cases" begin
    el = HTMLElement(:div)
    # No class attribute
    @test !hasclass(el, "test")

    # Empty class name throws
    @test_throws ArgumentError hasclass(el, "")
    @test_throws ArgumentError hasclass(el, "   ")

    # Partial match should not match
    addclass!(el, "foobar")
    @test !hasclass(el, "foo")
    @test hasclass(el, "foobar")
end

@testset "removeclass!" begin
    el = HTMLElement(:div)
    addclass!(el, "a")
    addclass!(el, "b")
    addclass!(el, "c")
    @test getattr(el, "class") == "a b c"

    removeclass!(el, "b")
    @test getattr(el, "class") == "a c"
    @test !hasclass(el, "b")

    # Removing non-existent class is a no-op
    removeclass!(el, "nonexistent")
    @test getattr(el, "class") == "a c"

    # Removing last class removes the attribute
    removeclass!(el, "a")
    removeclass!(el, "c")
    @test !hasattr(el, "class")
end

@testset "replaceclass!" begin
    el = HTMLElement(:div)
    addclass!(el, "old")
    addclass!(el, "keep")
    replaceclass!(el, "old", "new")
    @test hasclass(el, "new")
    @test hasclass(el, "keep")
    @test !hasclass(el, "old")

    # Replacing non-existent class is a no-op
    replaceclass!(el, "nonexistent", "replacement")
    @test !hasclass(el, "replacement")

    # Replace preserves order
    el2 = HTMLElement(:div)
    addclass!(el2, "a")
    addclass!(el2, "b")
    addclass!(el2, "c")
    replaceclass!(el2, "b", "x")
    classes = split(getattr(el2, "class"))
    @test classes == ["a", "x", "c"]

    # Returns the element
    el3 = HTMLElement(:div)
    addclass!(el3, "cls")
    result = replaceclass!(el3, "cls", "new")
    @test result === el3
end

@testset "setattr! and getattr" begin
    el = HTMLElement(:div)
    setattr!(el, "id", "test")
    @test getattr(el, "id") == "test"
    @test getattr(el, "missing") === nothing
    @test getattr(el, "missing", "default") == "default"

    # Symbol keys
    setattr!(el, :data_value, "42")
    @test getattr(el, :data_value) == "42"

    # Invalid attribute names throw
    @test_throws ArgumentError setattr!(el, "", "val")
    @test_throws HTMLForge.InvalidAttributeException setattr!(el, "a b", "val")
    @test_throws HTMLForge.InvalidAttributeException setattr!(el, "a>b", "val")
    @test_throws HTMLForge.InvalidAttributeException setattr!(el, "a=b", "val")
end

@testset "hasattr" begin
    el = HTMLElement(:div)
    @test !hasattr(el, "class")
    setattr!(el, "class", "test")
    @test hasattr(el, "class")
    @test hasattr(el, :class)
    @test !hasattr(el, "id")
end

@testset "indexing" begin
    parent = HTMLElement(:div)
    child1 = HTMLElement(:p)
    child2 = HTMLElement(:span)
    push!(parent, child1)
    push!(parent, child2)

    @test parent[1] === child1
    @test parent[2] === child2
    @test firstindex(parent) == 1
    @test lastindex(parent) == 2

    # Attribute indexing
    setattr!(parent, "id", "test")
    @test parent["id"] == "test"
    @test parent[:id] == "test"

    # Setindex for children
    new_child = HTMLElement(:a)
    parent[1] = new_child
    @test parent[1] === new_child
    @test new_child.parent === parent

    # Setindex for attributes
    parent["class"] = "wide"
    @test parent["class"] == "wide"
    parent[:style] = "color: red"
    @test parent["style"] == "color: red"
end

@testset "push! sets parent" begin
    parent = HTMLElement(:div)
    child = HTMLElement(:p)
    @test child.parent isa NullNode
    push!(parent, child)
    @test child.parent === parent

    # HTMLText child
    txt = HTMLText("hello")
    push!(parent, txt)
    @test txt.parent === parent
end

@testset "length" begin
    el = HTMLElement(:div)
    @test length(el) == 0
    push!(el, HTMLElement(:p))
    push!(el, HTMLElement(:span))
    @test length(el) == 2

    txt = HTMLText("hello world")
    @test length(txt) == 11
end

@testset "findfirst" begin
    root = HTMLElement(:div)
    p = HTMLElement(:p)
    span = HTMLElement(:span)
    setattr!(span, "id", "target")
    push!(p, span)
    push!(root, p)

    found = HTMLForge.findfirst(x -> hasattr(x, "id") && getattr(x, "id") == "target", root)
    @test found === span
    @test HTMLForge.findfirst(x -> false, root) === nothing

    # findfirst on HTMLDocument
    doc = HTMLDocument("html", root)
    found_doc = HTMLForge.findfirst(
        x -> hasattr(x, "id") && getattr(x, "id") == "target", doc)
    @test found_doc === span
end

@testset "getbyid" begin
    root = HTMLElement(:div)
    target = HTMLElement(:p)
    setattr!(target, "id", "findme")
    push!(root, target)

    @test getbyid(root, "findme") === target
    @test getbyid(root, "nothere") === nothing

    doc = HTMLDocument("html", root)
    @test getbyid(doc, "findme") === target
end

@testset "applyif!" begin
    root = HTMLElement(:div)
    p1 = HTMLElement(:p)
    p2 = HTMLElement(:p)
    span = HTMLElement(:span)
    push!(root, p1)
    push!(root, span)
    push!(root, p2)

    applyif!(x -> tag(x) == :p, x -> setattr!(x, "class", "para"), root)
    @test getattr(p1, "class") == "para"
    @test getattr(p2, "class") == "para"
    @test !hasattr(span, "class")

    # applyif! on HTMLDocument
    doc = HTMLDocument("html", root)
    applyif!(x -> tag(x) == :span, x -> setattr!(x, "class", "inline"), doc)
    @test getattr(span, "class") == "inline"
end

@testset "text extraction" begin
    el = HTMLElement(:div)
    push!(el, HTMLText("hello"))
    inner = HTMLElement(:strong)
    push!(inner, HTMLText("world"))
    push!(el, inner)
    @test text(el) == "hello world"

    # HTMLText text
    t = HTMLText("just text")
    @test text(t) == "just text"

    # Empty element
    empty_el = HTMLElement(:div)
    @test text(empty_el) == ""
end

@testset "body and head helpers" begin
    doc = parsehtml("<html><head><title>T</title></head><body><p>B</p></body></html>")
    @test tag(HTMLForge.body(doc)) == :body
    @test tag(HTMLForge.head(doc)) == :head
    @test tag(HTMLForge.body(doc.root)) == :body
    @test tag(HTMLForge.head(doc.root)) == :head
end

@testset "traversal aliases" begin
    root = HTMLElement(:div)
    push!(root, HTMLElement(:p))
    push!(root, HTMLElement(:span))

    pre_nodes = collect(preorder(root))
    @test length(pre_nodes) >= 3  # root + 2 children

    post_nodes = collect(postorder(root))
    @test length(post_nodes) >= 3

    bf_nodes = collect(breadthfirst(root))
    @test length(bf_nodes) >= 3
end

@testset "attrs direct" begin
    el = HTMLElement(:div)
    setattr!(el, "id", "test")
    setattr!(el, "class", "foo")
    a = attrs(el)
    @test a isa Dict
    @test a["id"] == "test"
    @test a["class"] == "foo"
end

@testset "children of HTMLText" begin
    t = HTMLText("hello")
    @test HTMLForge.children(t) === ()
    @test isempty(HTMLForge.children(t))
end

@testset "setindex! child parent already matches" begin
    parent = HTMLElement(:div)
    child = HTMLElement(:p)
    push!(parent, child)
    @test child.parent === parent
    # setindex! where parent already matches — should not error
    parent[1] = child
    @test parent[1] === child
    @test child.parent === parent
end

@testset "push! child parent already matches" begin
    parent = HTMLElement(:div)
    child = HTMLElement(:p)
    push!(parent, child)
    @test child.parent === parent
    # push! again where parent already matches
    push!(parent, child)
    @test child.parent === parent
    @test length(parent) == 2
end

@testset "setindex! attribute with invalid key" begin
    el = HTMLElement(:div)
    @test_throws ArgumentError (el[""]="val")
    @test_throws HTMLForge.InvalidAttributeException (el["a b"]="val")
    @test_throws HTMLForge.InvalidAttributeException (el["a>b"]="val")
    # Symbol key validation
    @test_throws HTMLForge.InvalidAttributeException (el[Symbol("a=b")]="val")
end

@testset "replaceclass! with invalid newclass" begin
    el = HTMLElement(:div)
    addclass!(el, "old")
    @test_throws HTMLForge.InvalidAttributeException replaceclass!(el, "old", "a b")
    # Class should still be "old" since validation threw before replacement
    @test hasclass(el, "old")
end

@testset "body and head returning nothing" begin
    # Element with no body or head children
    el = HTMLElement(:div)
    push!(el, HTMLElement(:p))
    @test HTMLForge.body(el) === nothing
    @test HTMLForge.head(el) === nothing

    # Document with no body/head
    doc = HTMLDocument("html", el)
    @test HTMLForge.body(doc) === nothing
    @test HTMLForge.head(doc) === nothing
end