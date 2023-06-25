const HTMX_ATTRS = [:trigger, :target, :post, :get, :put, :patch, :delete, :swap, :indicator, :sync, :preserve, :include, :params, :encoding, :confirm, :disinherit, :boost, :select, :pushurl, :selectoob, :swapoob, :historyelt]
const HIPHENATED = Dict(:pushurl => Symbol("push-url"), :selectoob => Symbol("select-oob"), :swapoob => Symbol("swap-oob"), :historyelt => Symbol("history-elt"))

_hyphenate(x::Symbol) = haskey(HIPHENATED, x) ? HIPHENATED[x] : x

function hx(el::HTMLElement; kw...)
    hxattrs = Dict("hx-$(_hyphenate(Symbol(k)))" => string(v) for (k,v) in kw) 
    HTMLElement{tag(el)}(el.children, el.parent, merge(attrs(el), hxattrs))
end

Base.propertynames(::Type{hx}) = HTMX_ATTRS
function Base.getproperty(::Type{hx}, name::Symbol) 
    if name in HTMX_ATTRS
        _hyphenate(name)
    else 
        error("hx does not have property $name")
    end
end

