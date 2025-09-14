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
