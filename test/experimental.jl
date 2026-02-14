using Test
using HTMLForge

# Include the Experimental module — this redefines hx functions + adds @hx macro and hx.* DSL
include(joinpath(pkgdir(HTMLForge), "src", "Experimental.jl"))

@testset "Experimental HTMX" begin

    # ══════════════════════════════════════════════
    # Internal helpers
    # ══════════════════════════════════════════════

    @testset "_hxnorm" begin
        # Bare attribute → prefixed
        @test _hxnorm("get") == "data-hx-get"
        @test _hxnorm(:get) == "data-hx-get"

        # hx- prefix → normalized to data-hx-
        @test _hxnorm("hx-get") == "data-hx-get"
        @test _hxnorm("hx-trigger") == "data-hx-trigger"

        # data-hx- prefix → unchanged
        @test _hxnorm("data-hx-get") == "data-hx-get"
        @test _hxnorm("data-hx-target") == "data-hx-target"

        # Symbol inputs
        @test _hxnorm(:target) == "data-hx-target"
        @test _hxnorm(Symbol("hx-swap")) == "data-hx-swap"
        @test _hxnorm(Symbol("data-hx-swap")) == "data-hx-swap"

        # Compound attribute names
        @test _hxnorm("swap-oob") == "data-hx-swap-oob"
        @test _hxnorm("push-url") == "data-hx-push-url"
        @test _hxnorm("replace-url") == "data-hx-replace-url"
        @test _hxnorm("disabled-elt") == "data-hx-disabled-elt"
        @test _hxnorm("history-elt") == "data-hx-history-elt"
        @test _hxnorm("select-oob") == "data-hx-select-oob"

        # Single character
        @test _hxnorm("x") == "data-hx-x"
        @test _hxnorm(:x) == "data-hx-x"
    end

    @testset "_R registry completeness" begin
        # All expected value attributes
        value_attrs = [:get, :post, :put, :patch, :delete,
            :target, :select, :swapoob, :selectoob,
            :vals, :pushurl, :replaceurl,
            :confirm, :prompt, :indicator, :boost,
            :include, :params, :headers, :sync,
            :encoding, :ext, :disinherit, :inherit,
            :history, :request, :disabledelt]
        for attr in value_attrs
            @test haskey(_R, attr)
            @test _R[attr][2] == :v
        end

        # All expected flag attributes
        flag_attrs = [:disable, :preserve, :validate, :historyelt]
        for attr in flag_attrs
            @test haskey(_R, attr)
            @test _R[attr][2] == :f
        end

        # Total count
        @test length(_R) == length(value_attrs) + length(flag_attrs)
    end

    @testset "_SWAPS constant" begin
        expected = Set(["innerHTML", "outerHTML", "afterbegin", "beforebegin",
            "beforeend", "afterend", "delete", "none"])
        @test _SWAPS == expected
        @test length(_SWAPS) == 8
    end

    # ══════════════════════════════════════════════
    # Interface 1: Classic auto-generated functions
    # ══════════════════════════════════════════════

    @testset "auto-generated value functions" begin
        # Test every value attribute function from the registry
        test_cases = [
            (:hxget!, "get", "/api"),
            (:hxpost!, "post", "/submit"),
            (:hxput!, "put", "/update"),
            (:hxpatch!, "patch", "/partial"),
            (:hxdelete!, "delete", "/remove"),
            (:hxtarget!, "target", "#result"),
            (:hxselect!, "select", "#content"),
            (:hxswapoob!, "swap-oob", "true"),
            (:hxselectoob!, "select-oob", "#a,#b"),
            (:hxvals!, "vals", "{\"k\":\"v\"}"),
            (:hxpushurl!, "push-url", "true"),
            (:hxreplaceurl!, "replace-url", "/new"),
            (:hxconfirm!, "confirm", "Sure?"),
            (:hxprompt!, "prompt", "Enter value"),
            (:hxindicator!, "indicator", "#spinner"),
            (:hxboost!, "boost", "true"),
            (:hxinclude!, "include", "#form"),
            (:hxparams!, "params", "*"),
            (:hxheaders!, "headers", "{\"X-H\":\"v\"}"),
            (:hxsync!, "sync", "this:drop"),
            (:hxencoding!, "encoding", "multipart/form-data"),
            (:hxext!, "ext", "sse"),
            (:hxdisinherit!, "disinherit", "*"),
            (:hxinherit!, "inherit", "hx-target"),
            (:hxhistory!, "history", "false"),
            (:hxrequest!, "request", "timeout:3000"),
            (:hxdisabledelt!, "disabled-elt", "this")
        ]

        for (fn_sym, attr_suffix, value) in test_cases
            fn = getfield(Main, fn_sym)
            el = HTMLElement(:div)
            result = fn(el, value)
            @test result === el  # mutates in place
            @test getattr(el, "data-hx-$attr_suffix") == value
        end
    end

    @testset "auto-generated flag functions" begin
        flag_cases = [
            (:hxdisable!, "disable"),
            (:hxpreserve!, "preserve"),
            (:hxvalidate!, "validate"),
            (:hxhistoryelt!, "history-elt")
        ]

        for (fn_sym, attr_suffix) in flag_cases
            fn = getfield(Main, fn_sym)
            el = HTMLElement(:div)
            result = fn(el)
            @test result === el
            @test getattr(el, "data-hx-$attr_suffix") == ""
        end
    end

    @testset "value functions with empty strings" begin
        el = HTMLElement(:div)
        hxget!(el, "")
        @test getattr(el, "data-hx-get") == ""

        el2 = HTMLElement(:div)
        hxtarget!(el2, "")
        @test getattr(el2, "data-hx-target") == ""
    end

    @testset "value functions overwrite" begin
        el = HTMLElement(:div)
        hxget!(el, "/first")
        @test getattr(el, "data-hx-get") == "/first"
        hxget!(el, "/second")
        @test getattr(el, "data-hx-get") == "/second"
    end

    @testset "multiple attributes on same element" begin
        el = HTMLElement(:button)
        hxpost!(el, "/submit")
        hxtarget!(el, "#result")
        hxconfirm!(el, "Sure?")
        @test getattr(el, "data-hx-post") == "/submit"
        @test getattr(el, "data-hx-target") == "#result"
        @test getattr(el, "data-hx-confirm") == "Sure?"
    end

    @testset "special characters in values" begin
        el = HTMLElement(:div)
        hxvals!(el, "{\"key\": \"value with spaces & <special> chars\"}")
        @test getattr(el, "data-hx-vals") ==
              "{\"key\": \"value with spaces & <special> chars\"}"

        el2 = HTMLElement(:div)
        hxheaders!(el2, "js:{\"X-Token\": getToken()}")
        @test getattr(el2, "data-hx-headers") == "js:{\"X-Token\": getToken()}"
    end

    # ══════════════════════════════════════════════
    # hxattr! (generic setter)
    # ══════════════════════════════════════════════

    @testset "hxattr! basic" begin
        el = HTMLElement(:div)
        result = hxattr!(el, "custom", "value")
        @test result === el
        @test getattr(el, "data-hx-custom") == "value"
    end

    @testset "hxattr! prefix normalization" begin
        # Bare name
        el = HTMLElement(:div)
        hxattr!(el, "target", "#x")
        @test getattr(el, "data-hx-target") == "#x"

        # hx- prefix
        el2 = HTMLElement(:div)
        hxattr!(el2, "hx-target", "#y")
        @test getattr(el2, "data-hx-target") == "#y"

        # data-hx- prefix
        el3 = HTMLElement(:div)
        hxattr!(el3, "data-hx-target", "#z")
        @test getattr(el3, "data-hx-target") == "#z"

        # Symbol
        el4 = HTMLElement(:div)
        hxattr!(el4, :boost, "true")
        @test getattr(el4, "data-hx-boost") == "true"
    end

    @testset "hxattr! empty value" begin
        el = HTMLElement(:div)
        hxattr!(el, "ext", "")
        @test getattr(el, "data-hx-ext") == ""
    end

    # ══════════════════════════════════════════════
    # hxrequest! (method setter)
    # ══════════════════════════════════════════════

    @testset "hxrequest! all methods" begin
        for method in [:get, :post, :put, :patch, :delete]
            el = HTMLElement(:div)
            result = hxrequest!(el, method, "/url")
            @test result === el
            @test getattr(el, "data-hx-$(method)") == "/url"
        end
    end

    @testset "hxrequest! string methods" begin
        el = HTMLElement(:div)
        hxrequest!(el, "get", "/api")
        @test getattr(el, "data-hx-get") == "/api"

        # Mixed case
        el2 = HTMLElement(:div)
        hxrequest!(el2, "POST", "/submit")
        @test getattr(el2, "data-hx-post") == "/submit"

        el3 = HTMLElement(:div)
        hxrequest!(el3, "Delete", "/item")
        @test getattr(el3, "data-hx-delete") == "/item"
    end

    @testset "hxrequest! URL edge cases" begin
        # Query params
        el = HTMLElement(:div)
        hxrequest!(el, :get, "/search?q=test&page=1")
        @test getattr(el, "data-hx-get") == "/search?q=test&page=1"

        # Fragment
        el2 = HTMLElement(:div)
        hxrequest!(el2, :get, "/page#section")
        @test getattr(el2, "data-hx-get") == "/page#section"

        # Empty URL
        el3 = HTMLElement(:div)
        hxrequest!(el3, :post, "")
        @test getattr(el3, "data-hx-post") == ""

        # Full URL
        el4 = HTMLElement(:div)
        hxrequest!(el4, :get, "https://example.com/api/v2?key=val")
        @test getattr(el4, "data-hx-get") == "https://example.com/api/v2?key=val"
    end

    # ══════════════════════════════════════════════
    # hxtrigger! — full modifier support
    # ══════════════════════════════════════════════

    @testset "hxtrigger! basic event" begin
        el = HTMLElement(:div)
        result = hxtrigger!(el, "click")
        @test result === el
        @test getattr(el, "data-hx-trigger") == "click"
    end

    @testset "hxtrigger! with filter" begin
        el = HTMLElement(:div)
        hxtrigger!(el, "click"; filter = "ctrlKey")
        @test getattr(el, "data-hx-trigger") == "click[ctrlKey]"

        # Complex JS filter
        el2 = HTMLElement(:div)
        hxtrigger!(el2, "keyup"; filter = "ctrlKey && shiftKey")
        @test getattr(el2, "data-hx-trigger") == "keyup[ctrlKey && shiftKey]"

        # Filter with detail access
        el3 = HTMLElement(:div)
        hxtrigger!(el3, "myEvent"; filter = "event.detail.level === 'important'")
        @test getattr(el3, "data-hx-trigger") ==
              "myEvent[event.detail.level === 'important']"
    end

    @testset "hxtrigger! individual modifiers" begin
        # once
        el = HTMLElement(:div)
        hxtrigger!(el, "click"; once = true)
        @test getattr(el, "data-hx-trigger") == "click once"

        # changed
        el2 = HTMLElement(:input)
        hxtrigger!(el2, "keyup"; changed = true)
        @test getattr(el2, "data-hx-trigger") == "keyup changed"

        # delay
        el3 = HTMLElement(:input)
        hxtrigger!(el3, "keyup"; delay = "500ms")
        @test getattr(el3, "data-hx-trigger") == "keyup delay:500ms"

        # throttle
        el4 = HTMLElement(:div)
        hxtrigger!(el4, "scroll"; throttle = "1s")
        @test getattr(el4, "data-hx-trigger") == "scroll throttle:1s"

        # from
        el5 = HTMLElement(:div)
        hxtrigger!(el5, "click"; from = "#other-element")
        @test getattr(el5, "data-hx-trigger") == "click from:#other-element"

        # target
        el6 = HTMLElement(:div)
        hxtrigger!(el6, "click"; target = ".child")
        @test getattr(el6, "data-hx-trigger") == "click target:.child"

        # consume
        el7 = HTMLElement(:div)
        hxtrigger!(el7, "click"; consume = true)
        @test getattr(el7, "data-hx-trigger") == "click consume"

        # queue
        for q in ["first", "last", "all", "none"]
            el = HTMLElement(:div)
            hxtrigger!(el, "click"; queue = q)
            @test getattr(el, "data-hx-trigger") == "click queue:$q"
        end
    end

    @testset "hxtrigger! multiple modifiers" begin
        el = HTMLElement(:input)
        hxtrigger!(el, "keyup"; changed = true, delay = "500ms")
        @test getattr(el, "data-hx-trigger") == "keyup changed delay:500ms"
    end

    @testset "hxtrigger! all modifiers combined" begin
        el = HTMLElement(:input)
        hxtrigger!(el, "keyup"; once = true, changed = true, delay = "500ms",
            throttle = "1s", from = "#form", target = ".input",
            consume = true, queue = "last", filter = "shiftKey")
        trigger = getattr(el, "data-hx-trigger")
        @test occursin("keyup[shiftKey]", trigger)
        @test occursin("once", trigger)
        @test occursin("changed", trigger)
        @test occursin("delay:500ms", trigger)
        @test occursin("throttle:1s", trigger)
        @test occursin("from:#form", trigger)
        @test occursin("target:.input", trigger)
        @test occursin("consume", trigger)
        @test occursin("queue:last", trigger)
    end

    @testset "hxtrigger! default booleans produce no modifier" begin
        el = HTMLElement(:div)
        hxtrigger!(el, "mouseenter"; once = false, changed = false, consume = false)
        @test getattr(el, "data-hx-trigger") == "mouseenter"
    end

    @testset "hxtrigger! various event names" begin
        for event in ["click", "mouseenter", "mouseleave", "keyup", "keydown",
            "change", "submit", "focus", "blur", "input", "load", "revealed"]
            el = HTMLElement(:div)
            hxtrigger!(el, event)
            @test getattr(el, "data-hx-trigger") == event
        end
    end

    @testset "hxtrigger! special from selectors" begin
        for src in ["document", "window", "closest div", "find .child"]
            el = HTMLElement(:div)
            hxtrigger!(el, "click"; from = src)
            @test getattr(el, "data-hx-trigger") == "click from:$src"
        end
    end

    @testset "hxtrigger! overwrite" begin
        el = HTMLElement(:div)
        hxtrigger!(el, "click")
        @test getattr(el, "data-hx-trigger") == "click"
        hxtrigger!(el, "mouseenter"; once = true)
        @test getattr(el, "data-hx-trigger") == "mouseenter once"
    end

    @testset "hxtrigger! filter with modifier" begin
        el = HTMLElement(:div)
        hxtrigger!(el, "click"; filter = "altKey", once = true)
        trigger = getattr(el, "data-hx-trigger")
        @test occursin("click[altKey]", trigger)
        @test occursin("once", trigger)
    end

    # ══════════════════════════════════════════════
    # hxswap! — validated swap with modifiers
    # ══════════════════════════════════════════════

    @testset "hxswap! all valid styles" begin
        for style in ["innerHTML", "outerHTML", "afterbegin", "beforebegin",
            "beforeend", "afterend", "delete", "none"]
            el = HTMLElement(:div)
            result = hxswap!(el, style)
            @test result === el
            @test getattr(el, "data-hx-swap") == style
        end
    end

    @testset "hxswap! invalid style throws" begin
        el = HTMLElement(:div)
        @test_throws ArgumentError hxswap!(el, "invalid")
        @test_throws ArgumentError hxswap!(el, "innerhtml")      # case-sensitive
        @test_throws ArgumentError hxswap!(el, "INNERHTML")
        @test_throws ArgumentError hxswap!(el, "replace")
        @test_throws ArgumentError hxswap!(el, "append")
        @test_throws ArgumentError hxswap!(el, "prepend")
        @test_throws ArgumentError hxswap!(el, "")
    end

    @testset "hxswap! error message content" begin
        el = HTMLElement(:div)
        try
            hxswap!(el, "badstyle")
            @test false  # Should not reach here
        catch e
            @test e isa ArgumentError
            @test occursin("badstyle", string(e))
        end
    end

    @testset "hxswap! individual modifiers" begin
        # transition true
        el = HTMLElement(:div)
        hxswap!(el, "outerHTML"; transition = true)
        @test getattr(el, "data-hx-swap") == "outerHTML transition:true"

        # transition false
        el2 = HTMLElement(:div)
        hxswap!(el2, "innerHTML"; transition = false)
        @test getattr(el2, "data-hx-swap") == "innerHTML transition:false"

        # swap delay
        el3 = HTMLElement(:div)
        hxswap!(el3, "innerHTML"; swap = "100ms")
        @test getattr(el3, "data-hx-swap") == "innerHTML swap:100ms"

        # settle delay
        el4 = HTMLElement(:div)
        hxswap!(el4, "innerHTML"; settle = "200ms")
        @test getattr(el4, "data-hx-swap") == "innerHTML settle:200ms"

        # ignoreTitle true/false
        el5 = HTMLElement(:div)
        hxswap!(el5, "outerHTML"; ignoreTitle = true)
        @test getattr(el5, "data-hx-swap") == "outerHTML ignoreTitle:true"

        el5b = HTMLElement(:div)
        hxswap!(el5b, "innerHTML"; ignoreTitle = false)
        @test getattr(el5b, "data-hx-swap") == "innerHTML ignoreTitle:false"

        # scroll top/bottom
        el6 = HTMLElement(:div)
        hxswap!(el6, "innerHTML"; scroll = "top")
        @test getattr(el6, "data-hx-swap") == "innerHTML scroll:top"

        el6b = HTMLElement(:div)
        hxswap!(el6b, "innerHTML"; scroll = "bottom")
        @test getattr(el6b, "data-hx-swap") == "innerHTML scroll:bottom"

        # show top/bottom
        el7 = HTMLElement(:div)
        hxswap!(el7, "innerHTML"; show = "top")
        @test getattr(el7, "data-hx-swap") == "innerHTML show:top"

        el7b = HTMLElement(:div)
        hxswap!(el7b, "innerHTML"; show = "bottom")
        @test getattr(el7b, "data-hx-swap") == "innerHTML show:bottom"

        # focusScroll true/false
        el8 = HTMLElement(:div)
        hxswap!(el8, "innerHTML"; focusScroll = true)
        @test getattr(el8, "data-hx-swap") == "innerHTML focus-scroll:true"

        el8b = HTMLElement(:div)
        hxswap!(el8b, "innerHTML"; focusScroll = false)
        @test getattr(el8b, "data-hx-swap") == "innerHTML focus-scroll:false"
    end

    @testset "hxswap! all modifiers combined" begin
        el = HTMLElement(:div)
        hxswap!(el, "outerHTML";
            transition = true, swap = "50ms", settle = "100ms",
            ignoreTitle = true, scroll = "top", show = "bottom", focusScroll = false)
        swap_val = getattr(el, "data-hx-swap")
        @test startswith(swap_val, "outerHTML")
        @test occursin("transition:true", swap_val)
        @test occursin("swap:50ms", swap_val)
        @test occursin("settle:100ms", swap_val)
        @test occursin("ignoreTitle:true", swap_val)
        @test occursin("scroll:top", swap_val)
        @test occursin("show:bottom", swap_val)
        @test occursin("focus-scroll:false", swap_val)
    end

    @testset "hxswap! no modifiers" begin
        el = HTMLElement(:div)
        hxswap!(el, "delete")
        @test getattr(el, "data-hx-swap") == "delete"
    end

    @testset "hxswap! overwrite" begin
        el = HTMLElement(:div)
        hxswap!(el, "innerHTML")
        hxswap!(el, "outerHTML"; transition = true)
        @test occursin("outerHTML", getattr(el, "data-hx-swap"))
    end

    # ══════════════════════════════════════════════
    # hxon! — event handler
    # ══════════════════════════════════════════════

    @testset "hxon! basic" begin
        el = HTMLElement(:button)
        result = hxon!(el, "click", "alert('hi')")
        @test result === el
        @test getattr(el, "data-hx-on:click") == "alert('hi')"
    end

    @testset "hxon! htmx events" begin
        for event in ["htmx:before-request", "htmx:after-request",
            "htmx:before-swap", "htmx:after-swap",
            "htmx:before-settle", "htmx:after-settle",
            "htmx:load", "htmx:xhr:loadend"]
            el = HTMLElement(:div)
            hxon!(el, event, "console.log('event')")
            @test getattr(el, "data-hx-on:$event") == "console.log('event')"
        end
    end

    @testset "hxon! DOM events" begin
        for event in ["click", "dblclick", "mousedown", "keydown",
            "submit", "change", "focus", "blur"]
            el = HTMLElement(:div)
            hxon!(el, event, "handler()")
            @test getattr(el, "data-hx-on:$event") == "handler()"
        end
    end

    @testset "hxon! multiple handlers on same element" begin
        el = HTMLElement(:button)
        hxon!(el, "click", "handleClick()")
        hxon!(el, "mouseenter", "handleHover()")
        @test getattr(el, "data-hx-on:click") == "handleClick()"
        @test getattr(el, "data-hx-on:mouseenter") == "handleHover()"
    end

    @testset "hxon! complex script" begin
        el = HTMLElement(:form)
        script = "if (event.detail.successful) { alert('ok'); } else { alert('fail'); }"
        hxon!(el, "htmx:after-request", script)
        @test getattr(el, "data-hx-on:htmx:after-request") == script
    end

    # ══════════════════════════════════════════════
    # Specialty triggers
    # ══════════════════════════════════════════════

    @testset "load_trigger" begin
        el = HTMLElement(:div)
        result = load_trigger(el)
        @test result === el
        @test getattr(el, "data-hx-trigger") == "load"

        el2 = HTMLElement(:div)
        load_trigger(el2; delay = "1s")
        @test getattr(el2, "data-hx-trigger") == "load delay:1s"

        el3 = HTMLElement(:div)
        load_trigger(el3; delay = "500ms")
        @test getattr(el3, "data-hx-trigger") == "load delay:500ms"

        el4 = HTMLElement(:div)
        load_trigger(el4; delay = nothing)
        @test getattr(el4, "data-hx-trigger") == "load"
    end

    @testset "revealed_trigger" begin
        el = HTMLElement(:div)
        result = revealed_trigger(el)
        @test result === el
        @test getattr(el, "data-hx-trigger") == "revealed once"

        # once=false
        el2 = HTMLElement(:div)
        revealed_trigger(el2; once = false)
        @test getattr(el2, "data-hx-trigger") == "revealed"

        # explicit once=true
        el3 = HTMLElement(:div)
        revealed_trigger(el3; once = true)
        @test getattr(el3, "data-hx-trigger") == "revealed once"
    end

    @testset "poll_trigger" begin
        el = HTMLElement(:div)
        result = poll_trigger(el, "2s")
        @test result === el
        @test getattr(el, "data-hx-trigger") == "every 2s"

        for interval in ["100ms", "1s", "5s", "30s", "500ms"]
            el = HTMLElement(:div)
            poll_trigger(el, interval)
            @test getattr(el, "data-hx-trigger") == "every $interval"
        end
    end

    @testset "intersect_trigger basic" begin
        el = HTMLElement(:div)
        result = intersect_trigger(el)
        @test result === el
        @test getattr(el, "data-hx-trigger") == "intersect once"
    end

    @testset "intersect_trigger with threshold" begin
        el = HTMLElement(:div)
        intersect_trigger(el; threshold = 0.5)
        @test occursin("threshold:0.5", getattr(el, "data-hx-trigger"))
    end

    @testset "intersect_trigger with root" begin
        el = HTMLElement(:div)
        intersect_trigger(el; root = "#viewport")
        trigger = getattr(el, "data-hx-trigger")
        @test occursin("root:#viewport", trigger)
        @test !occursin("threshold", trigger)
    end

    @testset "intersect_trigger with root and threshold" begin
        el = HTMLElement(:div)
        intersect_trigger(el; root = "#viewport", threshold = 0.8, once = false)
        trigger = getattr(el, "data-hx-trigger")
        @test occursin("root:#viewport", trigger)
        @test occursin("threshold:0.8", trigger)
        @test !occursin("once", trigger)
    end

    @testset "intersect_trigger threshold clamping" begin
        # Above 1.0 → clamped to 1.0
        el = HTMLElement(:div)
        intersect_trigger(el; threshold = 1.5)
        @test occursin("threshold:1.0", getattr(el, "data-hx-trigger"))

        # Below 0.0 → clamped to 0.0
        el2 = HTMLElement(:div)
        intersect_trigger(el2; threshold = -0.5)
        @test occursin("threshold:0.0", getattr(el2, "data-hx-trigger"))

        # Exact boundaries
        el3 = HTMLElement(:div)
        intersect_trigger(el3; threshold = 0.0)
        @test occursin("threshold:0.0", getattr(el3, "data-hx-trigger"))

        el4 = HTMLElement(:div)
        intersect_trigger(el4; threshold = 1.0)
        @test occursin("threshold:1.0", getattr(el4, "data-hx-trigger"))

        # Integer input (Real type)
        el5 = HTMLElement(:div)
        intersect_trigger(el5; threshold = 1)
        @test occursin("threshold:1.0", getattr(el5, "data-hx-trigger"))
    end

    @testset "intersect_trigger once=false" begin
        el = HTMLElement(:div)
        intersect_trigger(el; once = false)
        trigger = getattr(el, "data-hx-trigger")
        @test startswith(trigger, "intersect")
        @test !occursin("once", trigger)
    end

    # ══════════════════════════════════════════════
    # Interface 2: @hx macro
    # ══════════════════════════════════════════════

    @testset "@hx create new element from symbol" begin
        btn = @hx :button get="/api" trigger="click" target="#result"
        @test tag(btn) == :button
        @test getattr(btn, "data-hx-get") == "/api"
        @test getattr(btn, "data-hx-trigger") == "click"
        @test getattr(btn, "data-hx-target") == "#result"
    end

    @testset "@hx create various element types" begin
        d = @hx :div get="/test"
        @test tag(d) == :div

        sp = @hx :span post="/data"
        @test tag(sp) == :span

        f = @hx :form post="/submit"
        @test tag(f) == :form

        inp = @hx :input get="/search"
        @test tag(inp) == :input
    end

    @testset "@hx modify existing element" begin
        el = HTMLElement(:form)
        @hx el post="/submit" swap="outerHTML" confirm="Sure?"
        @test getattr(el, "data-hx-post") == "/submit"
        @test getattr(el, "data-hx-swap") == "outerHTML"
        @test getattr(el, "data-hx-confirm") == "Sure?"
    end

    @testset "@hx underscore to hyphen conversion" begin
        el = @hx :div push_url="true" replace_url="/new"
        @test getattr(el, "data-hx-push-url") == "true"
        @test getattr(el, "data-hx-replace-url") == "/new"

        el2 = @hx :div disabled_elt="this" history_elt="" swap_oob="true" select_oob="#a"
        @test getattr(el2, "data-hx-disabled-elt") == "this"
        @test getattr(el2, "data-hx-history-elt") == ""
        @test getattr(el2, "data-hx-swap-oob") == "true"
        @test getattr(el2, "data-hx-select-oob") == "#a"
    end

    @testset "@hx expression interpolation" begin
        url = "/api/v2/items"
        btn = @hx :button get=url
        @test getattr(btn, "data-hx-get") == url

        # String concatenation
        base = "/api"
        endpoint = @hx :div get=(base * "/data")
        @test getattr(endpoint, "data-hx-get") == "/api/data"

        # Integer value converted via string()
        num = 42
        el = @hx :div boost=num
        @test getattr(el, "data-hx-boost") == "42"
    end

    @testset "@hx single attribute" begin
        el = @hx :div get="/single"
        @test getattr(el, "data-hx-get") == "/single"
    end

    @testset "@hx many attributes" begin
        el = @hx :button post="/submit" trigger="click" target="#result" swap="outerHTML" confirm="Sure?" indicator="#spinner"
        @test getattr(el, "data-hx-post") == "/submit"
        @test getattr(el, "data-hx-trigger") == "click"
        @test getattr(el, "data-hx-target") == "#result"
        @test getattr(el, "data-hx-swap") == "outerHTML"
        @test getattr(el, "data-hx-confirm") == "Sure?"
        @test getattr(el, "data-hx-indicator") == "#spinner"
    end

    @testset "@hx returns the element" begin
        result = @hx :div get="/test"
        @test result isa HTMLElement
        @test tag(result) == :div
    end

    @testset "@hx modifying existing preserves other attrs" begin
        el = HTMLElement(:button)
        el["id"] = "my-btn"
        el["class"] = "primary"
        @hx el post="/submit"
        @test getattr(el, "id") == "my-btn"
        @test getattr(el, "class") == "primary"
        @test getattr(el, "data-hx-post") == "/submit"
    end

    # ══════════════════════════════════════════════
    # Interface 3: hx.* Pipe DSL
    # ══════════════════════════════════════════════

    @testset "hx pipe: value attributes" begin
        value_pipes = [
            (:get, "get", "/api"),
            (:post, "post", "/submit"),
            (:put, "put", "/update"),
            (:patch, "patch", "/partial"),
            (:delete, "delete", "/remove"),
            (:target, "target", "#result"),
            (:select, "select", "#content"),
            (:swapoob, "swap-oob", "true"),
            (:selectoob, "select-oob", "#a,#b"),
            (:vals, "vals", "{\"k\":1}"),
            (:pushurl, "push-url", "true"),
            (:replaceurl, "replace-url", "/new"),
            (:confirm, "confirm", "Sure?"),
            (:prompt, "prompt", "Enter"),
            (:indicator, "indicator", "#spinner"),
            (:boost, "boost", "true"),
            (:include, "include", "#form"),
            (:params, "params", "*"),
            (:headers, "headers", "{}"),
            (:sync, "sync", "this:drop"),
            (:encoding, "encoding", "multipart/form-data"),
            (:ext, "ext", "sse"),
            (:disinherit, "disinherit", "*"),
            (:inherit, "inherit", "hx-target"),
            (:history, "history", "false"),
            (:request, "request", "timeout:3000"),
            (:disabledelt, "disabled-elt", "this")
        ]

        for (name, attr_suffix, value) in value_pipes
            el = HTMLElement(:div) |> getproperty(hx, name)(value)
            @test getattr(el, "data-hx-$attr_suffix") == value
        end
    end

    @testset "hx pipe: flag attributes" begin
        flag_pipes = [
            (:disable, "disable"),
            (:preserve, "preserve"),
            (:validate, "validate"),
            (:historyelt, "history-elt")
        ]

        for (name, attr_suffix) in flag_pipes
            el = HTMLElement(:div) |> getproperty(hx, name)()
            @test getattr(el, "data-hx-$attr_suffix") == ""
        end
    end

    @testset "hx pipe: trigger with modifiers" begin
        el = HTMLElement(:div) |> hx.trigger("click"; once = true)
        @test getattr(el, "data-hx-trigger") == "click once"

        el2 = HTMLElement(:div) |> hx.trigger("keyup"; changed = true, delay = "300ms")
        @test getattr(el2, "data-hx-trigger") == "keyup changed delay:300ms"

        el3 = HTMLElement(:div) |> hx.trigger("click"; filter = "ctrlKey", consume = true)
        trigger = getattr(el3, "data-hx-trigger")
        @test occursin("click[ctrlKey]", trigger)
        @test occursin("consume", trigger)
    end

    @testset "hx pipe: swap with modifiers" begin
        el = HTMLElement(:div) |> hx.swap("outerHTML"; transition = true)
        @test occursin("outerHTML", getattr(el, "data-hx-swap"))
        @test occursin("transition:true", getattr(el, "data-hx-swap"))

        el2 = HTMLElement(:div) |>
              hx.swap("innerHTML"; focusScroll = false, settle = "200ms")
        swap_val = getattr(el2, "data-hx-swap")
        @test occursin("innerHTML", swap_val)
        @test occursin("focus-scroll:false", swap_val)
        @test occursin("settle:200ms", swap_val)
    end

    @testset "hx pipe: swap invalid style throws" begin
        @test_throws ArgumentError HTMLElement(:div)|>hx.swap("invalid")
        @test_throws ArgumentError HTMLElement(:div)|>hx.swap("")
    end

    @testset "hx pipe: on event handler" begin
        el = HTMLElement(:button) |> hx.on("click", "alert('hi')")
        @test getattr(el, "data-hx-on:click") == "alert('hi')"

        el2 = HTMLElement(:div) |> hx.on("htmx:before-request", "showLoader()")
        @test getattr(el2, "data-hx-on:htmx:before-request") == "showLoader()"
    end

    @testset "hx pipe: unknown attribute errors" begin
        @test_throws ErrorException getproperty(hx, :nonexistent)
        @test_throws ErrorException getproperty(hx, :bogus)
    end

    @testset "hx pipe: chaining multiple operations" begin
        el = HTMLElement(:button) |>
             hx.post("/submit") |>
             hx.target("#result") |>
             hx.swap("outerHTML") |>
             hx.trigger("click"; once = true) |>
             hx.confirm("Sure?")

        @test getattr(el, "data-hx-post") == "/submit"
        @test getattr(el, "data-hx-target") == "#result"
        @test getattr(el, "data-hx-swap") == "outerHTML"
        @test getattr(el, "data-hx-trigger") == "click once"
        @test getattr(el, "data-hx-confirm") == "Sure?"
    end

    @testset "hx pipe: complex chain with all modifier types" begin
        el = HTMLElement(:button) |>
             hx.post("/api/submit") |>
             hx.trigger("click"; once = true) |>
             hx.target("#response") |>
             hx.swap("outerHTML"; transition = true, settle = "200ms") |>
             hx.confirm("Proceed?") |>
             hx.indicator("#spinner") |>
             hx.headers("{\"X-Token\": \"abc\"}") |>
             hx.on("htmx:after-request", "hideLoader()")

        @test getattr(el, "data-hx-post") == "/api/submit"
        @test getattr(el, "data-hx-trigger") == "click once"
        @test getattr(el, "data-hx-target") == "#response"
        @test occursin("outerHTML", getattr(el, "data-hx-swap"))
        @test occursin("transition:true", getattr(el, "data-hx-swap"))
        @test occursin("settle:200ms", getattr(el, "data-hx-swap"))
        @test getattr(el, "data-hx-confirm") == "Proceed?"
        @test getattr(el, "data-hx-indicator") == "#spinner"
        @test getattr(el, "data-hx-headers") == "{\"X-Token\": \"abc\"}"
        @test getattr(el, "data-hx-on:htmx:after-request") == "hideLoader()"
    end

    @testset "hx pipe: flag attrs in chain" begin
        el = HTMLElement(:div) |>
             hx.disable() |>
             hx.preserve()
        @test getattr(el, "data-hx-disable") == ""
        @test getattr(el, "data-hx-preserve") == ""
    end

    # ══════════════════════════════════════════════
    # Cross-interface equivalence
    # ══════════════════════════════════════════════

    @testset "three interfaces produce identical results" begin
        # Classic
        el1 = HTMLElement(:button)
        hxpost!(el1, "/submit")
        hxtarget!(el1, "#result")
        hxswap!(el1, "outerHTML")
        hxtrigger!(el1, "click"; once = true)
        hxconfirm!(el1, "Sure?")

        # @hx macro (note: swap here won't have modifiers since it's a string)
        el2 = @hx :button post="/submit" target="#result" swap="outerHTML" trigger="click" confirm="Sure?"

        # Pipe DSL
        el3 = HTMLElement(:button) |>
              hx.post("/submit") |>
              hx.target("#result") |>
              hx.swap("outerHTML") |>
              hx.trigger("click"; once = true) |>
              hx.confirm("Sure?")

        # Classic and Pipe have identical attributes for trigger (once modifier applied)
        @test getattr(el1, "data-hx-post") == getattr(el3, "data-hx-post")
        @test getattr(el1, "data-hx-target") == getattr(el3, "data-hx-target")
        @test getattr(el1, "data-hx-swap") == getattr(el3, "data-hx-swap")
        @test getattr(el1, "data-hx-trigger") == getattr(el3, "data-hx-trigger")
        @test getattr(el1, "data-hx-confirm") == getattr(el3, "data-hx-confirm")

        # Macro produces simple string values (no modifier parsing)
        @test getattr(el2, "data-hx-post") == "/submit"
        @test getattr(el2, "data-hx-target") == "#result"
        @test getattr(el2, "data-hx-swap") == "outerHTML"
        @test getattr(el2, "data-hx-trigger") == "click"   # macro sets raw string, no "once"
        @test getattr(el2, "data-hx-confirm") == "Sure?"
    end

    @testset "classic vs pipe: value attributes identical" begin
        for (name, attr_suffix) in [(:get, "get"), (:post, "post"), (:target, "target"),
            (:confirm, "confirm"), (:ext, "ext"), (:boost, "boost")]
            el_classic = HTMLElement(:div)
            fn = getfield(Main, Symbol(:hx, name, :!))
            fn(el_classic, "test_value")

            el_pipe = HTMLElement(:div) |> getproperty(hx, name)("test_value")

            @test getattr(el_classic, "data-hx-$attr_suffix") ==
                  getattr(el_pipe, "data-hx-$attr_suffix")
        end
    end

    @testset "classic vs pipe: flag attributes identical" begin
        for (name, attr_suffix) in [(:disable, "disable"), (:preserve, "preserve"),
            (:validate, "validate"), (:historyelt, "history-elt")]
            el_classic = HTMLElement(:div)
            fn = getfield(Main, Symbol(:hx, name, :!))
            fn(el_classic)

            el_pipe = HTMLElement(:div) |> getproperty(hx, name)()

            @test getattr(el_classic, "data-hx-$attr_suffix") ==
                  getattr(el_pipe, "data-hx-$attr_suffix")
        end
    end

    # ══════════════════════════════════════════════
    # Integration / real-world patterns
    # ══════════════════════════════════════════════

    @testset "active search pattern (pipe)" begin
        el = HTMLElement(:input) |>
             hx.get("/search") |>
             hx.trigger("keyup"; changed = true, delay = "500ms") |>
             hx.target("#search-results") |>
             hx.indicator("#spinner")

        @test getattr(el, "data-hx-get") == "/search"
        @test getattr(el, "data-hx-trigger") == "keyup changed delay:500ms"
        @test getattr(el, "data-hx-target") == "#search-results"
        @test getattr(el, "data-hx-indicator") == "#spinner"
    end

    @testset "delete with confirm (pipe)" begin
        el = HTMLElement(:button) |>
             hx.delete("/account") |>
             hx.confirm("Are you sure you wish to delete your account?") |>
             hx.swap("outerHTML")

        @test getattr(el, "data-hx-delete") == "/account"
        @test getattr(el, "data-hx-confirm") ==
              "Are you sure you wish to delete your account?"
        @test getattr(el, "data-hx-swap") == "outerHTML"
    end

    @testset "file upload pattern (macro)" begin
        form = @hx :form post="/upload" encoding="multipart/form-data"
        @test getattr(form, "data-hx-post") == "/upload"
        @test getattr(form, "data-hx-encoding") == "multipart/form-data"
    end

    @testset "infinite scroll (pipe)" begin
        el = HTMLElement(:div) |>
             hx.get("/api/items?page=2") |>
             hx.trigger("revealed") |>
             hx.swap("afterend")

        @test getattr(el, "data-hx-get") == "/api/items?page=2"
        @test getattr(el, "data-hx-trigger") == "revealed"
        @test getattr(el, "data-hx-swap") == "afterend"
    end

    @testset "progress bar polling (pipe)" begin
        el = HTMLElement(:div)
        poll_trigger(el, "600ms")
        el = el |> hx.get("/job/123/progress") |> hx.swap("outerHTML")

        @test getattr(el, "data-hx-get") == "/job/123/progress"
        @test getattr(el, "data-hx-trigger") == "every 600ms"
        @test getattr(el, "data-hx-swap") == "outerHTML"
    end

    @testset "form with all features (classic)" begin
        form = HTMLElement(:form)
        hxpost!(form, "/api/contacts")
        hxtrigger!(form, "submit")
        hxtarget!(form, "#contact-list")
        hxswap!(form, "beforeend"; settle = "500ms")
        hxindicator!(form, "#form-spinner")
        hxvalidate!(form)
        hxconfirm!(form, "Add this contact?")
        hxencoding!(form, "multipart/form-data")
        hxheaders!(form, "{\"X-CSRF\": \"token\"}")
        hxdisabledelt!(form, "find button")
        hxon!(form, "htmx:after-request", "resetForm()")

        @test getattr(form, "data-hx-post") == "/api/contacts"
        @test getattr(form, "data-hx-trigger") == "submit"
        @test getattr(form, "data-hx-target") == "#contact-list"
        @test occursin("beforeend", getattr(form, "data-hx-swap"))
        @test occursin("settle:500ms", getattr(form, "data-hx-swap"))
        @test getattr(form, "data-hx-indicator") == "#form-spinner"
        @test getattr(form, "data-hx-validate") == ""
        @test getattr(form, "data-hx-confirm") == "Add this contact?"
        @test getattr(form, "data-hx-encoding") == "multipart/form-data"
        @test getattr(form, "data-hx-headers") == "{\"X-CSRF\": \"token\"}"
        @test getattr(form, "data-hx-disabled-elt") == "find button"
        @test getattr(form, "data-hx-on:htmx:after-request") == "resetForm()"
    end

    @testset "inheritance control (macro)" begin
        parent = @hx :div boost="true" target="#content"
        child = @hx :div disinherit="hx-target"
        @test getattr(parent, "data-hx-boost") == "true"
        @test getattr(child, "data-hx-disinherit") == "hx-target"
    end

    @testset "history and preserve (pipe)" begin
        body = HTMLElement(:body) |> hx.history("false")
        @test getattr(body, "data-hx-history") == "false"

        video = HTMLElement(:video) |> hx.preserve()
        @test getattr(video, "data-hx-preserve") == ""
    end

    @testset "mixed regular and htmx attributes" begin
        el = HTMLElement(:button)
        el["id"] = "my-btn"
        el["class"] = "btn btn-primary"
        el = el |> hx.post("/submit") |> hx.trigger("click") |> hx.target("#output")

        @test getattr(el, "id") == "my-btn"
        @test getattr(el, "class") == "btn btn-primary"
        @test getattr(el, "data-hx-post") == "/submit"
        @test getattr(el, "data-hx-trigger") == "click"
        @test getattr(el, "data-hx-target") == "#output"
    end

    @testset "rendering piped element to string" begin
        el = HTMLElement(:button) |>
             hx.get("/api/data") |>
             hx.trigger("click") |>
             hx.target("#result") |>
             hx.swap("innerHTML")

        html = sprint(print, el)
        @test occursin("<button", html)
        @test occursin("data-hx-get=\"/api/data\"", html)
        @test occursin("data-hx-trigger=\"click\"", html)
        @test occursin("data-hx-target=\"#result\"", html)
        @test occursin("data-hx-swap=\"innerHTML\"", html)
    end

    @testset "rendering macro element to string" begin
        el = @hx :div get="/api" target="#out"
        html = sprint(print, el)
        @test occursin("<div", html)
        @test occursin("data-hx-get=\"/api\"", html)
        @test occursin("data-hx-target=\"#out\"", html)
    end

    @testset "rendering with entity encoding" begin
        el = HTMLElement(:div) |> hx.confirm("Are you sure? It's a \"big\" deal & final.")
        html = sprint(print, el)
        @test occursin("data-hx-confirm=", html)
        @test occursin("&amp;", html)
    end

    # ══════════════════════════════════════════════
    # Return value / chaining consistency
    # ══════════════════════════════════════════════

    @testset "all classic functions return element" begin
        el = HTMLElement(:button)
        # Value functions
        @test hxget!(el, "/a") === el
        @test hxpost!(el, "/b") === el
        @test hxput!(el, "/c") === el
        @test hxpatch!(el, "/d") === el
        @test hxdelete!(el, "/e") === el
        @test hxtarget!(el, "#t") === el
        @test hxselect!(el, "#s") === el
        @test hxswapoob!(el, "true") === el
        @test hxselectoob!(el, "#so") === el
        @test hxvals!(el, "{}") === el
        @test hxpushurl!(el, "true") === el
        @test hxreplaceurl!(el, "/new") === el
        @test hxconfirm!(el, "?") === el
        @test hxprompt!(el, "?") === el
        @test hxindicator!(el, "#i") === el
        @test hxboost!(el, "true") === el
        @test hxinclude!(el, "#inc") === el
        @test hxparams!(el, "*") === el
        @test hxheaders!(el, "{}") === el
        @test hxsync!(el, "this:drop") === el
        @test hxencoding!(el, "multipart/form-data") === el
        @test hxext!(el, "ext") === el
        @test hxdisinherit!(el, "*") === el
        @test hxinherit!(el, "*") === el
        @test hxhistory!(el, "false") === el
        @test hxrequest!(el, :get, "/a") === el

        # Actually hxrequest! from Experimental takes (el, "request", val) for config registry
        # but also has the separate hxrequest! function. Let's test its return
        @test hxrequest!(el, :get, "/a") === el

        @test hxdisabledelt!(el, "this") === el

        # Flag functions
        @test hxdisable!(el) === el
        @test hxpreserve!(el) === el
        @test hxvalidate!(el) === el
        @test hxhistoryelt!(el) === el

        # Complex functions
        @test hxattr!(el, "custom", "val") === el
        @test hxtrigger!(el, "click") === el
        @test hxswap!(el, "innerHTML") === el
        @test hxon!(el, "click", "fn()") === el
    end

    @testset "pipe closures return element" begin
        el = HTMLElement(:div)
        # Value pipe
        @test (hx.get("/api"))(el) === el
        # Flag pipe
        @test (hx.disable())(el) === el
        # Trigger pipe
        @test (hx.trigger("click"))(el) === el
        # Swap pipe
        @test (hx.swap("innerHTML"))(el) === el
        # On pipe
        @test (hx.on("click", "fn()"))(el) === el
    end

    # ══════════════════════════════════════════════
    # Edge cases: void elements, text content
    # ══════════════════════════════════════════════

    @testset "piped void elements" begin
        el = HTMLElement(:input) |> hx.get("/search") |>
             hx.trigger("keyup"; delay = "300ms")
        html = sprint(print, el)
        @test occursin("<input", html)
        @test occursin("/>", html)
        @test occursin("data-hx-get=\"/search\"", html)
        @test !occursin("</input>", html)
    end

    @testset "element with text content" begin
        el = HTMLElement(:button)
        push!(el, HTMLText("Click me"))
        el = el |> hx.post("/action") |> hx.trigger("click")
        html = sprint(print, el)
        @test occursin("Click me", html)
        @test occursin("data-hx-post=\"/action\"", html)
    end

    @testset "macro element with children" begin
        parent = @hx :div get="/content" target="this" swap="innerHTML"
        child = HTMLElement(:span)
        push!(child, HTMLText("Loading..."))
        push!(parent, child)

        html = sprint(print, parent)
        @test occursin("<div", html)
        @test occursin("data-hx-get=\"/content\"", html)
        @test occursin("<span>Loading...</span>", html)
    end
end
