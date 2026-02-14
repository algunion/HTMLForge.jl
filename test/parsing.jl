# basic test that parsing works correctly

@test_throws HTMLForge.InvalidHTMLException parsehtml("", strict = true)

@testset "parsing with parents" begin
    page = open("$testdir/fixtures/example.html") do example
        read(example, String) |> parsehtml
    end
    @test page.doctype == "html"
    root = page.root
    @test tag(root[1][1]) == :meta
    @test root[2][1][1].text == "A simple test page."
    @test root[2][1][1].parent === root[2][1]
end

@testset "parsing without parents" begin
    page = open("$testdir/fixtures/example.html") do example
        parsehtml(read(example, String), include_parent = false)
    end
    @test page.doctype == "html"
    root = page.root
    @test tag(root[1][1]) == :meta
    @test root[2][1][1].text == "A simple test page."
    @test root[2][1][1].parent === NullNode()
end

@testset "test snippet parsing" begin
    snip = parsehtml_snippet("<div><p>hello</p></div>")
    @test tag(snip) == :div
    @test tag(snip[1]) == :p
    @test snip[1][1].text == "hello"
    @test snip.parent === NullNode()
end

@testset "snippet with multiple top-level tags" begin
    snip = parsehtml_snippet("<p>one</p><p>two</p>")
    @test tag(snip) == :div  # wrapped in div
    @test length(children(snip)) == 2
    @test tag(snip[1]) == :p
    @test tag(snip[2]) == :p
end

@testset "snippet empty input" begin
    @test_throws ArgumentError parsehtml_snippet("")
end

# test that nonexistant tags are parsed as their actual name and not "unknown"

let
    page = parsehtml("<weird></weird")
    @test tag(page.root[2][1]) == :weird
end

# test that non-standard tags, with attributes, are parsed correctly

let
    page = HTMLForge.parsehtml("<my-element cool></my-element>")
    @test tag(page.root[2][1]) == Symbol("my-element")
    @test HTMLForge.attrs(page.root[2][1]) == Dict("cool" => "")
end

@testset "parsehtml non-strict mode" begin
    # Invalid HTML should not throw in non-strict mode (default)
    doc = parsehtml("<div><p>unclosed")
    @test doc isa HTMLForge.HTMLDocument
end

@testset "parsehtml preserve_whitespace" begin
    doc = parsehtml("<pre>  spaces  </pre>", preserve_whitespace = true)
    @test doc isa HTMLForge.HTMLDocument
end
