const HTMX_ATTRS = [:trigger, :target, :post, :get, :put, :patch, :delete, :swap, :indicator, :sync, :preserve, :include, :params, :encoding, :confirm, :disinherit, :boost, :select, :pushurl, :selectoob, :swapoob, :historyelt]
const HIPHENATED = Dict(:pushurl => Symbol("push-url"), :selectoob => Symbol("select-oob"), :swapoob => Symbol("swap-oob"), :historyelt => Symbol("history-elt"))

function hx(node::HTMLElement, attr::String, value::String)
    node.attributes[attr] = value
    return node
end