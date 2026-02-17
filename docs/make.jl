using Documenter
using HTMLForge

makedocs(;
    modules = [HTMLForge],
    sitename = "HTMLForge.jl",
    authors = "Marius Fersigan and contributors",
    doctest = false,
    warnonly = [:missing_docs, :cross_references, :docs_block],
    format = Documenter.HTML(;
        prettyurls = get(ENV, "CI", nothing) == "true",
        canonical = "https://algunion.github.io/HTMLForge.jl",
        edit_link = "main",
        assets = String[]
    ),
    pages = [
        "Home" => "index.md",
        "Getting Started" => "getting_started.md",
        "HTML Types" => "types.md",
        "Parsing" => "parsing.md",
        "Manipulation" => "manipulation.md",
        "Traversal" => "traversal.md",
        "HTMX Support" => "htmx.md",
        "Experimental HTMX" => "experimental.md",
        "API Reference" => "api.md",
        "LLM Reference" => "llm.md"
    ]
)

deploydocs(;
    repo = "github.com/algunion/HTMLForge.jl",
    devbranch = "main"
)
