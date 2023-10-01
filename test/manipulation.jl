@testset "HTML manipulation" begin
    doc = open("$testdir/fixtures/attrs_test.html") do attrstest
        read(attrstest, String) |> parsehtml
    end
    @test doc.root |> tag == :HTML
    @test length(doc.root[2]) == 5    
    @test length(doc.root[2][1][1]) == 26
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
    addclass!(doc.root, "narrow")
    addclass!(doc.root, "another")
    replaceclass!(doc.root, "narrow", "wide")
    @test hasclass(doc.root, "wide")
end