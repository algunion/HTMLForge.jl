
let
    # roundtrip test
    # TODO this could be done with Quickcheck if we had a way of
    # generating "interesting" HTML documents
    doc = open("$testdir/fixtures/example.html") do example
        read(example, String) |> parsehtml
    end
    io = IOBuffer()
    print(io, doc)
    seek(io, 0)
    newdoc = read(io, String) |> parsehtml
    @test newdoc == doc
end

tests = [
    "30",  # regression test for issue #30
    "multitext",  # regression test for multiple HTMLText in one HTMLElement
    "varied",  # relatively complex example
    "whitespace",  # whitespace sensitive
    "whitespace2",  # whitespace sensitive
    "template"  # preserve template
]
@testset for test in tests
    let
        doc = open("$testdir/fixtures/$(test)_input.html") do example
            parsehtml(read(example, String), preserve_whitespace = (test == "whitespace"),
                preserve_template = (test == "template"))
        end
        io = IOBuffer()
        print(io, doc.root, pretty = (test != "whitespace"))
        seek(io, 0)
        ground_truth = read(open("$testdir/fixtures/$(test)_output.html"), String)
        # Eliminate possible line ending issues
        ground_truth = replace(ground_truth, "\r\n" => "\n")
        @test read(io, String) == ground_truth
    end
end

@testset "xml entities" begin
    io = IOBuffer()

    orig = """<p class="asd&gt;&amp;-2&quot;">&lt;faketag&gt;</p>"""
    print(io, parsehtml(orig))
    @test occursin(orig, String(take!(io)))
end

@testset "prettyprint" begin
    el = HTMLElement(:div)
    push!(el, HTMLElement(:p))

    # prettyprint to IO
    io = IOBuffer()
    prettyprint(io, el)
    output = String(take!(io))
    @test occursin("<div>", output)
    @test occursin("<p>", output)

    # prettyprint HTMLDocument
    doc = HTMLDocument("html", HTMLElement(:html))
    io2 = IOBuffer()
    prettyprint(io2, doc)
    output2 = String(take!(io2))
    @test occursin("<!DOCTYPE html>", output2)
end

@testset "show HTMLElement" begin
    el = HTMLElement(:div)
    push!(el, HTMLText("hello"))

    # Default show
    io = IOBuffer()
    show(io, el)
    output = String(take!(io))
    @test occursin("HTMLElement", output)

    # Compact show
    io2 = IOBuffer()
    show(IOContext(io2, :compact => true), el)
    output2 = String(take!(io2))
    @test occursin("HTMLElement", output2)

    # Limited show
    io3 = IOBuffer()
    show(IOContext(io3, :limit => true), el)
    output3 = String(take!(io3))
    @test occursin("HTMLElement", output3)
end

@testset "show HTMLText" begin
    t = HTMLText("hello world")
    io = IOBuffer()
    show(io, t)
    output = String(take!(io))
    @test occursin("HTML Text:", output)
    @test occursin("hello world", output)
end

@testset "show HTMLDocument" begin
    doc = HTMLDocument("html", HTMLElement(:html))
    io = IOBuffer()
    show(io, doc)
    output = String(take!(io))
    @test occursin("HTML Document:", output)
    @test occursin("<!DOCTYPE html>", output)
end

@testset "print HTMLText" begin
    t = HTMLText("hello <world>")

    # With substitution (default)
    io = IOBuffer()
    print(io, t)
    @test String(take!(io)) == "hello &lt;world&gt;"

    # Without substitution
    io2 = IOBuffer()
    print(io2, t; substitution = false)
    @test String(take!(io2)) == "hello <world>"

    # Pretty print
    io3 = IOBuffer()
    print(io3, t; pretty = true)
    output = String(take!(io3))
    @test occursin("hello", output)
end

@testset "empty tags" begin
    el = HTMLElement(:br)
    io = IOBuffer()
    print(io, el)
    @test String(take!(io)) == "<br/>"

    el2 = HTMLElement(:img)
    setattr!(el2, "src", "test.png")
    io2 = IOBuffer()
    print(io2, el2)
    @test occursin("<img", String(take!(io2)))
    @test !occursin("</img>", String(take!(io2)))  # empty tags have no closing tag
end

@testset "entity substitution in attributes" begin
    el = HTMLElement(:div)
    setattr!(el, "data-value", "a\"b'c<d>e&f")
    io = IOBuffer()
    print(io, el)
    output = String(take!(io))
    @test occursin("&quot;", output)
    @test occursin("&#39;", output)
    @test occursin("&lt;", output)
    @test occursin("&gt;", output)
    @test occursin("&amp;", output)
end

@testset "no entity substitution in script/style" begin
    script = HTMLElement(:script)
    push!(script, HTMLText("var x = 1 < 2 && 3 > 1;"))
    io = IOBuffer()
    print(io, script)
    output = String(take!(io))
    @test occursin("1 < 2 && 3 > 1", output)
    @test !occursin("&lt;", output)
end
