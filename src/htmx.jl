using URIs

const HXPREFIX = "data-hx-"
const HXREQUESTS = [:get, :post, :put, :patch, :delete]
const HTMX_ATTRS = [
    :trigger, :target, :post, :get, :put, :patch, :delete, :swap, :indicator,
    :sync, :preserve, :include, :params, :encoding, :confirm, :disinherit,
    :boost, :select, :pushurl, :selectoob, :swapoob, :historyelt]
const HIPHENATED = Dict(:pushurl => Symbol("push-url"), :selectoob => Symbol("select-oob"),
    :swapoob => Symbol("swap-oob"), :historyelt => Symbol("history-elt"))

"""
    _hyphenate(x::Symbol) -> Symbol
Convert a symbol to its htmx hyphenated equivalent if it exists in the HIPHENATED dictionary, otherwise return the symbol unchanged.
"""
_hyphenate(x::Symbol) = haskey(HIPHENATED, x) ? HIPHENATED[x] : x

"""
    _hxprefix(x::Symbol) -> Symbol
Ensure that a symbol has the "hx-" prefix. If it already has the prefix, return it unchanged; otherwise, prepend "hx-" to the symbol.
"""
_hxprefix(x::Symbol) = startswith(string(x), HXPREFIX) ? x : Symbol(HXPREFIX, _hyphenate(x))

"""
    hx(el::HTMLElement; kw...) -> HTMLElement
Add htmx attributes to an `HTMLElement` and return a new `HTMLElement`.
"""
function hx(el::HTMLElement; kw...)
    hxattrs = Dict(_hxprefix(k) => v for (k, v) in kw)
    HTMLElement(tag(el), el.children, el.parent, merge(attrs(el), hxattrs))
end

"""
    hx!(el::HTMLElement; kw...) -> HTMLElement
Add htmx attributes to an `HTMLElement` in place and return the modified `HTMLElement`.
"""
function hx!(el::HTMLElement; kw...)
    hxattrs = Dict("$(_hyphenate(Symbol(k)))" => string(v) for (k, v) in kw)
    merge!(el.attributes, hxattrs)
    el
end

struct HXRequest
    method::Symbol
    url::URI
    function HXRequest(method::Symbol, url::URI)
        method ∈ HXREQUESTS || throw(ArgumentError("Invalid HTTP method: $method"))
        new(method, url)
    end
end

function HXRequest(method::Symbol, url::AbstractString)
    method ∈ HXREQUESTS || throw(ArgumentError("Invalid HTTP method: $method"))
    HXRequest(method, URI(url))
end

function hx!(el::HTMLElement, req::HXRequest)
    setattr!(el, string(_hxprefix(req.method)), string(req.url))
end
