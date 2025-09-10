module HTMLForge
using GumboBinaries_jll, Libdl

include("CGumbo.jl")

export HTMLElement,
    HTMLDocument,
    HTMLText,
    NullNode,
    HTMLNode,
    attrs,
    text,
    tag,
    children,
    hasattr,
    getattr,
    setattr!,
    findfirst,
    getbyid,
    applyif!,
    hasclass,
    addclass!,
    removeclass!,
    replaceclass!,
    parsehtml,
    parsehtml_snippet,
    postorder,
    preorder,
    breadthfirst,
    prettyprint

include("htmltypes.jl")
include("manipulation.jl")
include("comparison.jl")
include("htmx.jl")
include("io.jl")
include("conversion.jl")

end
