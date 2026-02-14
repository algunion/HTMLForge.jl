module HTMLForge
import Unicode
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
       prettyprint,
# htmx - generic
       hxattr!,
# htmx - AJAX request attributes
       hxget!,
       hxpost!,
       hxput!,
       hxpatch!,
       hxdelete!,
       hxrequest!,
# htmx - trigger
       hxtrigger!,
# htmx - core attributes
       hxtarget!,
       hxswap!,
       hxswapoob!,
       hxselect!,
       hxselectoob!,
       hxvals!,
       hxpushurl!,
       hxreplaceurl!,
# htmx - additional attributes
       hxconfirm!,
       hxprompt!,
       hxindicator!,
       hxboost!,
       hxinclude!,
       hxparams!,
       hxheaders!,
       hxsync!,
       hxencoding!,
       hxext!,
       hxon!,
       hxdisable!,
       hxdisabledelt!,
       hxdisinherit!,
       hxinherit!,
       hxhistory!,
       hxhistoryelt!,
       hxpreserve!,
       hxrequestconfig!,
       hxvalidate!,
       @validate

include("htmltypes.jl")
include("validation.jl")
include("manipulation.jl")
include("comparison.jl")
include("htmx.jl")
include("io.jl")
include("conversion.jl")

end
