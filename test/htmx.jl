using Test
using HTMLForge
import HTMLForge: ensurehxprefix, load_trigger, revealed_trigger,
                  intersect_trigger, poll_trigger, VALID_SWAP_STYLES

@testset "htmx" begin
    # ──────────────────────────────────────────────
    # ensurehxprefix
    # ──────────────────────────────────────────────
    @testset "ensurehxprefix" begin
        @test ensurehxprefix("get") == "data-hx-get"
        @test ensurehxprefix(:get) == "data-hx-get"
        @test ensurehxprefix("hx-get") == "data-hx-get"
        @test ensurehxprefix("data-hx-get") == "data-hx-get"
        @test ensurehxprefix("trigger") == "data-hx-trigger"
        @test ensurehxprefix(:trigger) == "data-hx-trigger"
        @test ensurehxprefix("hx-trigger") == "data-hx-trigger"
    end

    @testset "ensurehxprefix edge cases" begin
        # Symbol with data-hx- prefix already
        @test ensurehxprefix(Symbol("data-hx-target")) == "data-hx-target"
        # Symbol with hx- prefix
        @test ensurehxprefix(Symbol("hx-swap")) == "data-hx-swap"
        # Long compound attribute names
        @test ensurehxprefix("swap-oob") == "data-hx-swap-oob"
        @test ensurehxprefix("disabled-elt") == "data-hx-disabled-elt"
        @test ensurehxprefix("replace-url") == "data-hx-replace-url"
        @test ensurehxprefix("push-url") == "data-hx-push-url"
        @test ensurehxprefix("history-elt") == "data-hx-history-elt"
        @test ensurehxprefix("select-oob") == "data-hx-select-oob"
        # Single character attribute
        @test ensurehxprefix("x") == "data-hx-x"
        @test ensurehxprefix(:x) == "data-hx-x"
        # Various htmx attribs via Symbol
        @test ensurehxprefix(:boost) == "data-hx-boost"
        @test ensurehxprefix(:confirm) == "data-hx-confirm"
        @test ensurehxprefix(:indicator) == "data-hx-indicator"
    end

    # ──────────────────────────────────────────────
    # hxattr!
    # ──────────────────────────────────────────────
    @testset "hxattr!" begin
        el = HTMLElement(:div)
        result = hxattr!(el, "custom", "value")
        @test result === el
        @test getattr(el, "data-hx-custom") == "value"
    end

    @testset "hxattr! edge cases" begin
        # Symbol attr argument
        el = HTMLElement(:div)
        hxattr!(el, :loading, "lazy")
        @test getattr(el, "data-hx-loading") == "lazy"

        # Attr already has hx- prefix → gets converted to data-hx-
        el2 = HTMLElement(:div)
        hxattr!(el2, "hx-custom", "val")
        @test getattr(el2, "data-hx-custom") == "val"

        # Attr already has data-hx- prefix → stays as is
        el3 = HTMLElement(:div)
        hxattr!(el3, "data-hx-custom", "val2")
        @test getattr(el3, "data-hx-custom") == "val2"

        # Empty value string
        el4 = HTMLElement(:div)
        hxattr!(el4, "ext", "")
        @test getattr(el4, "data-hx-ext") == ""

        # Overwriting an existing htmx attribute
        el5 = HTMLElement(:div)
        hxattr!(el5, "target", "#first")
        @test getattr(el5, "data-hx-target") == "#first"
        hxattr!(el5, "target", "#second")
        @test getattr(el5, "data-hx-target") == "#second"

        # Value with special characters
        el6 = HTMLElement(:div)
        hxattr!(el6, "vals", "{\"key\": \"value with spaces & symbols <>\"}}")
        @test getattr(el6, "data-hx-vals") ==
              "{\"key\": \"value with spaces & symbols <>\"}}"
    end

    # ──────────────────────────────────────────────
    # hxrequest!
    # ──────────────────────────────────────────────
    @testset "hxrequest!" begin
        el = HTMLElement(:div)
        result = hxrequest!(el, :get, "/api/data")
        @test result === el  # mutates in place
        @test getattr(el, "data-hx-get") == "/api/data"

        el2 = HTMLElement(:button)
        hxrequest!(el2, "post", "/api/submit")
        @test getattr(el2, "data-hx-post") == "/api/submit"

        el3 = HTMLElement(:form)
        hxrequest!(el3, :put, "/api/update")
        @test getattr(el3, "data-hx-put") == "/api/update"

        el4 = HTMLElement(:span)
        hxrequest!(el4, :patch, "/api/patch")
        @test getattr(el4, "data-hx-patch") == "/api/patch"

        el5 = HTMLElement(:a)
        hxrequest!(el5, :delete, "/api/remove")
        @test getattr(el5, "data-hx-delete") == "/api/remove"
    end

    @testset "hxrequest! edge cases" begin
        # Mixed case string method → lowercased
        el = HTMLElement(:div)
        hxrequest!(el, "GET", "/api/upper")
        @test getattr(el, "data-hx-get") == "/api/upper"

        el2 = HTMLElement(:div)
        hxrequest!(el2, "Post", "/api/mixed")
        @test getattr(el2, "data-hx-post") == "/api/mixed"

        el3 = HTMLElement(:div)
        hxrequest!(el3, "DELETE", "/api/upper-delete")
        @test getattr(el3, "data-hx-delete") == "/api/upper-delete"

        # URL with query params
        el4 = HTMLElement(:div)
        hxrequest!(el4, :get, "/api/search?q=test&page=1")
        @test getattr(el4, "data-hx-get") == "/api/search?q=test&page=1"

        # URL with fragment
        el5 = HTMLElement(:div)
        hxrequest!(el5, :get, "/page#section")
        @test getattr(el5, "data-hx-get") == "/page#section"

        # Empty URL
        el6 = HTMLElement(:div)
        hxrequest!(el6, :post, "")
        @test getattr(el6, "data-hx-post") == ""

        # Overwriting a request method
        el7 = HTMLElement(:div)
        hxrequest!(el7, :get, "/first")
        @test getattr(el7, "data-hx-get") == "/first"
        hxrequest!(el7, :get, "/second")
        @test getattr(el7, "data-hx-get") == "/second"

        # Multiple different methods on same element
        el8 = HTMLElement(:div)
        hxrequest!(el8, :get, "/get-url")
        hxrequest!(el8, :post, "/post-url")
        @test getattr(el8, "data-hx-get") == "/get-url"
        @test getattr(el8, "data-hx-post") == "/post-url"
    end

    # ──────────────────────────────────────────────
    # Convenience AJAX method shortcuts
    # ──────────────────────────────────────────────
    @testset "hxget!" begin
        el = HTMLElement(:div)
        result = hxget!(el, "/api/items")
        @test result === el
        @test getattr(el, "data-hx-get") == "/api/items"
    end

    @testset "hxget! edge cases" begin
        # Various element types
        for tag_sym in [:div, :button, :span, :a, :form, :input, :table, :tr, :td, :li]
            el = HTMLElement(tag_sym)
            hxget!(el, "/test")
            @test getattr(el, "data-hx-get") == "/test"
        end
        # URL with encoded characters
        el = HTMLElement(:div)
        hxget!(el, "/api/items?name=hello%20world&type=a%26b")
        @test getattr(el, "data-hx-get") == "/api/items?name=hello%20world&type=a%26b"
    end

    @testset "hxpost!" begin
        el = HTMLElement(:form)
        result = hxpost!(el, "/api/submit")
        @test result === el
        @test getattr(el, "data-hx-post") == "/api/submit"
    end

    @testset "hxpost! edge cases" begin
        el = HTMLElement(:button)
        hxpost!(el, "/api/submit?redirect=true")
        @test getattr(el, "data-hx-post") == "/api/submit?redirect=true"
    end

    @testset "hxput!" begin
        el = HTMLElement(:div)
        result = hxput!(el, "/api/update")
        @test result === el
        @test getattr(el, "data-hx-put") == "/api/update"
    end

    @testset "hxput! edge cases" begin
        el = HTMLElement(:form)
        hxput!(el, "/api/resource/123")
        @test getattr(el, "data-hx-put") == "/api/resource/123"
    end

    @testset "hxpatch!" begin
        el = HTMLElement(:div)
        result = hxpatch!(el, "/api/patch")
        @test result === el
        @test getattr(el, "data-hx-patch") == "/api/patch"
    end

    @testset "hxpatch! edge cases" begin
        el = HTMLElement(:span)
        hxpatch!(el, "/api/resource/456/field")
        @test getattr(el, "data-hx-patch") == "/api/resource/456/field"
    end

    @testset "hxdelete!" begin
        el = HTMLElement(:div)
        result = hxdelete!(el, "/api/remove")
        @test result === el
        @test getattr(el, "data-hx-delete") == "/api/remove"
    end

    @testset "hxdelete! edge cases" begin
        el = HTMLElement(:button)
        hxdelete!(el, "/api/resource/789")
        @test getattr(el, "data-hx-delete") == "/api/resource/789"
    end

    # ──────────────────────────────────────────────
    # hxtrigger! — basic and modifiers
    # ──────────────────────────────────────────────
    @testset "hxtrigger! basic" begin
        el = HTMLElement(:div)
        result = hxtrigger!(el, "click")
        @test result === el
        @test getattr(el, "data-hx-trigger") == "click"
    end

    @testset "hxtrigger! with filter" begin
        el = HTMLElement(:div)
        hxtrigger!(el, "click"; filter = "ctrlKey")
        @test getattr(el, "data-hx-trigger") == "click[ctrlKey]"
    end

    @testset "hxtrigger! with once" begin
        el = HTMLElement(:div)
        hxtrigger!(el, "click"; once = true)
        @test getattr(el, "data-hx-trigger") == "click once"
    end

    @testset "hxtrigger! with changed" begin
        el = HTMLElement(:input)
        hxtrigger!(el, "keyup"; changed = true)
        @test getattr(el, "data-hx-trigger") == "keyup changed"
    end

    @testset "hxtrigger! with delay" begin
        el = HTMLElement(:input)
        hxtrigger!(el, "keyup"; delay = "500ms")
        @test getattr(el, "data-hx-trigger") == "keyup delay:500ms"
    end

    @testset "hxtrigger! with throttle" begin
        el = HTMLElement(:div)
        hxtrigger!(el, "scroll"; throttle = "1s")
        @test getattr(el, "data-hx-trigger") == "scroll throttle:1s"
    end

    @testset "hxtrigger! with from" begin
        el = HTMLElement(:div)
        hxtrigger!(el, "click"; from = "#other-element")
        @test getattr(el, "data-hx-trigger") == "click from:#other-element"
    end

    @testset "hxtrigger! with target modifier" begin
        el = HTMLElement(:div)
        hxtrigger!(el, "click"; target = ".child")
        @test getattr(el, "data-hx-trigger") == "click target:.child"
    end

    @testset "hxtrigger! with consume" begin
        el = HTMLElement(:div)
        hxtrigger!(el, "click"; consume = true)
        @test getattr(el, "data-hx-trigger") == "click consume"
    end

    @testset "hxtrigger! with queue" begin
        el = HTMLElement(:div)
        hxtrigger!(el, "click"; queue = "last")
        @test getattr(el, "data-hx-trigger") == "click queue:last"

        el2 = HTMLElement(:div)
        hxtrigger!(el2, "click"; queue = "first")
        @test getattr(el2, "data-hx-trigger") == "click queue:first"

        el3 = HTMLElement(:div)
        hxtrigger!(el3, "click"; queue = "all")
        @test getattr(el3, "data-hx-trigger") == "click queue:all"

        el4 = HTMLElement(:div)
        hxtrigger!(el4, "click"; queue = "none")
        @test getattr(el4, "data-hx-trigger") == "click queue:none"
    end

    @testset "hxtrigger! with multiple modifiers" begin
        el = HTMLElement(:input)
        hxtrigger!(el, "keyup"; changed = true, delay = "500ms")
        @test getattr(el, "data-hx-trigger") == "keyup changed delay:500ms"
    end

    @testset "hxtrigger! with all modifiers" begin
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

    @testset "hxtrigger! edge cases" begin
        # Filter only, no other modifiers
        el = HTMLElement(:div)
        hxtrigger!(el, "click"; filter = "event.detail.level === 'important'")
        @test getattr(el, "data-hx-trigger") == "click[event.detail.level === 'important']"

        # Complex JS filter expression
        el2 = HTMLElement(:div)
        hxtrigger!(el2, "keyup"; filter = "ctrlKey && shiftKey")
        @test getattr(el2, "data-hx-trigger") == "keyup[ctrlKey && shiftKey]"

        # Filter combined with single modifier
        el3 = HTMLElement(:div)
        hxtrigger!(el3, "click"; filter = "altKey", once = true)
        trigger = getattr(el3, "data-hx-trigger")
        @test occursin("click[altKey]", trigger)
        @test occursin("once", trigger)

        # All boolean modifiers false by default — should produce just event
        el4 = HTMLElement(:div)
        hxtrigger!(el4, "mouseenter"; once = false, changed = false, consume = false)
        @test getattr(el4, "data-hx-trigger") == "mouseenter"

        # Various event types
        for event in ["click", "mouseenter", "mouseleave", "keyup", "keydown",
            "change", "submit", "focus", "blur", "input"]
            el = HTMLElement(:div)
            hxtrigger!(el, event)
            @test getattr(el, "data-hx-trigger") == event
        end

        # from with special selectors
        el5 = HTMLElement(:div)
        hxtrigger!(el5, "click"; from = "document")
        @test getattr(el5, "data-hx-trigger") == "click from:document"

        el6 = HTMLElement(:div)
        hxtrigger!(el6, "click"; from = "window")
        @test getattr(el6, "data-hx-trigger") == "click from:window"

        el7 = HTMLElement(:div)
        hxtrigger!(el7, "click"; from = "closest div")
        @test getattr(el7, "data-hx-trigger") == "click from:closest div"

        # Overwrite trigger on same element
        el8 = HTMLElement(:div)
        hxtrigger!(el8, "click")
        @test getattr(el8, "data-hx-trigger") == "click"
        hxtrigger!(el8, "mouseenter"; once = true)
        @test getattr(el8, "data-hx-trigger") == "mouseenter once"

        # delay and throttle together
        el9 = HTMLElement(:input)
        hxtrigger!(el9, "keyup"; delay = "300ms", throttle = "2s")
        trigger = getattr(el9, "data-hx-trigger")
        @test occursin("delay:300ms", trigger)
        @test occursin("throttle:2s", trigger)

        # from and target together
        el10 = HTMLElement(:div)
        hxtrigger!(el10, "click"; from = "#source", target = ".dest")
        trigger = getattr(el10, "data-hx-trigger")
        @test occursin("from:#source", trigger)
        @test occursin("target:.dest", trigger)
    end

    # ──────────────────────────────────────────────
    # Specialty triggers
    # ──────────────────────────────────────────────
    @testset "load_trigger" begin
        el = HTMLElement(:div)
        result = load_trigger(el)
        @test result === el
        @test getattr(el, "data-hx-trigger") == "load"

        el2 = HTMLElement(:div)
        load_trigger(el2; delay = "1s")
        @test getattr(el2, "data-hx-trigger") == "load delay:1s"
    end

    @testset "load_trigger edge cases" begin
        # Delay with milliseconds
        el = HTMLElement(:div)
        load_trigger(el; delay = "500ms")
        @test getattr(el, "data-hx-trigger") == "load delay:500ms"

        # No delay (nothing)
        el2 = HTMLElement(:div)
        load_trigger(el2; delay = nothing)
        @test getattr(el2, "data-hx-trigger") == "load"
    end

    @testset "revealed_trigger" begin
        el = HTMLElement(:div)
        result = revealed_trigger(el)
        @test result === el
        @test getattr(el, "data-hx-trigger") == "revealed once"

        el2 = HTMLElement(:div)
        revealed_trigger(el2; once = false)
        @test getattr(el2, "data-hx-trigger") == "revealed"
    end

    @testset "revealed_trigger edge cases" begin
        # Default is once=true
        el = HTMLElement(:section)
        revealed_trigger(el)
        @test occursin("once", getattr(el, "data-hx-trigger"))

        # Explicit once=true
        el2 = HTMLElement(:div)
        revealed_trigger(el2; once = true)
        @test getattr(el2, "data-hx-trigger") == "revealed once"
    end

    @testset "intersect_trigger" begin
        el = HTMLElement(:div)
        result = intersect_trigger(el)
        @test result === el
        @test getattr(el, "data-hx-trigger") == "intersect once"

        el2 = HTMLElement(:div)
        intersect_trigger(el2; threshold = 0.5)
        @test occursin("threshold:0.5", getattr(el2, "data-hx-trigger"))

        el3 = HTMLElement(:div)
        intersect_trigger(el3; root = "#viewport", threshold = 0.8, once = false)
        trigger = getattr(el3, "data-hx-trigger")
        @test occursin("root:#viewport", trigger)
        @test occursin("threshold:0.8", trigger)

        # threshold clamping
        el4 = HTMLElement(:div)
        intersect_trigger(el4; threshold = 1.5)
        @test occursin("threshold:1.0", getattr(el4, "data-hx-trigger"))

        el5 = HTMLElement(:div)
        intersect_trigger(el5; threshold = -0.5)
        @test occursin("threshold:0.0", getattr(el5, "data-hx-trigger"))
    end

    @testset "intersect_trigger edge cases" begin
        # Only root, no threshold
        el = HTMLElement(:div)
        intersect_trigger(el; root = "#container")
        trigger = getattr(el, "data-hx-trigger")
        @test occursin("root:#container", trigger)
        @test !occursin("threshold", trigger)

        # Threshold exactly 0
        el2 = HTMLElement(:div)
        intersect_trigger(el2; threshold = 0.0)
        @test occursin("threshold:0.0", getattr(el2, "data-hx-trigger"))

        # Threshold exactly 1
        el3 = HTMLElement(:div)
        intersect_trigger(el3; threshold = 1.0)
        @test occursin("threshold:1.0", getattr(el3, "data-hx-trigger"))

        # once=false without options
        el4 = HTMLElement(:div)
        intersect_trigger(el4; once = false)
        trigger = getattr(el4, "data-hx-trigger")
        @test startswith(trigger, "intersect")
        @test !occursin("once", trigger)

        # Threshold as integer (Real type)
        el5 = HTMLElement(:div)
        intersect_trigger(el5; threshold = 1)
        @test occursin("threshold:1.0", getattr(el5, "data-hx-trigger"))

        # Root and threshold and once=false
        el6 = HTMLElement(:div)
        intersect_trigger(el6; root = ".scroller", threshold = 0.25, once = false)
        trigger = getattr(el6, "data-hx-trigger")
        @test occursin("root:.scroller", trigger)
        @test occursin("threshold:0.25", trigger)
        @test !occursin("once", trigger)
    end

    @testset "poll_trigger" begin
        el = HTMLElement(:div)
        result = poll_trigger(el, "2s")
        @test result === el
        @test getattr(el, "data-hx-trigger") == "every 2s"

        el2 = HTMLElement(:div)
        poll_trigger(el2, "500ms")
        @test getattr(el2, "data-hx-trigger") == "every 500ms"
    end

    @testset "poll_trigger edge cases" begin
        # Various intervals
        for interval in ["100ms", "1s", "5s", "30s", "1m", "10m"]
            el = HTMLElement(:div)
            poll_trigger(el, interval)
            @test getattr(el, "data-hx-trigger") == "every $interval"
        end
    end

    # ──────────────────────────────────────────────
    # hxtarget!
    # ──────────────────────────────────────────────
    @testset "hxtarget!" begin
        el = HTMLElement(:div)
        result = hxtarget!(el, "#results")
        @test result === el
        @test getattr(el, "data-hx-target") == "#results"

        el2 = HTMLElement(:input)
        hxtarget!(el2, "this")
        @test getattr(el2, "data-hx-target") == "this"

        el3 = HTMLElement(:div)
        hxtarget!(el3, "closest tr")
        @test getattr(el3, "data-hx-target") == "closest tr"

        el4 = HTMLElement(:div)
        hxtarget!(el4, "find .content")
        @test getattr(el4, "data-hx-target") == "find .content"

        el5 = HTMLElement(:div)
        hxtarget!(el5, "next .sibling")
        @test getattr(el5, "data-hx-target") == "next .sibling"

        el6 = HTMLElement(:div)
        hxtarget!(el6, "previous .sibling")
        @test getattr(el6, "data-hx-target") == "previous .sibling"
    end

    @testset "hxtarget! edge cases" begin
        # Complex CSS selectors
        el = HTMLElement(:div)
        hxtarget!(el, "#main > .content:first-child")
        @test getattr(el, "data-hx-target") == "#main > .content:first-child"

        el2 = HTMLElement(:div)
        hxtarget!(el2, "closest form")
        @test getattr(el2, "data-hx-target") == "closest form"

        el3 = HTMLElement(:div)
        hxtarget!(el3, "find ul > li.active")
        @test getattr(el3, "data-hx-target") == "find ul > li.active"

        # Overwriting target
        el4 = HTMLElement(:div)
        hxtarget!(el4, "#first")
        @test getattr(el4, "data-hx-target") == "#first"
        hxtarget!(el4, "#second")
        @test getattr(el4, "data-hx-target") == "#second"

        # body target
        el5 = HTMLElement(:div)
        hxtarget!(el5, "body")
        @test getattr(el5, "data-hx-target") == "body"

        # next/previous without selector
        el6 = HTMLElement(:div)
        hxtarget!(el6, "next")
        @test getattr(el6, "data-hx-target") == "next"

        el7 = HTMLElement(:div)
        hxtarget!(el7, "previous")
        @test getattr(el7, "data-hx-target") == "previous"
    end

    # ──────────────────────────────────────────────
    # hxswap!
    # ──────────────────────────────────────────────
    @testset "hxswap! basic" begin
        for style in ["innerHTML", "outerHTML", "afterbegin", "beforebegin",
            "beforeend", "afterend", "delete", "none"]
            el = HTMLElement(:div)
            result = hxswap!(el, style)
            @test result === el
            @test getattr(el, "data-hx-swap") == style
        end
    end

    @testset "hxswap! VALID_SWAP_STYLES constant" begin
        # Ensure all styles in the constant are valid
        @test "innerHTML" in VALID_SWAP_STYLES
        @test "outerHTML" in VALID_SWAP_STYLES
        @test "afterbegin" in VALID_SWAP_STYLES
        @test "beforebegin" in VALID_SWAP_STYLES
        @test "beforeend" in VALID_SWAP_STYLES
        @test "afterend" in VALID_SWAP_STYLES
        @test "delete" in VALID_SWAP_STYLES
        @test "none" in VALID_SWAP_STYLES
        @test length(VALID_SWAP_STYLES) == 8
    end

    @testset "hxswap! with modifiers" begin
        el = HTMLElement(:div)
        hxswap!(el, "outerHTML"; transition = true)
        @test getattr(el, "data-hx-swap") == "outerHTML transition:true"

        el2 = HTMLElement(:div)
        hxswap!(el2, "innerHTML"; swap = "100ms")
        @test getattr(el2, "data-hx-swap") == "innerHTML swap:100ms"

        el3 = HTMLElement(:div)
        hxswap!(el3, "innerHTML"; settle = "200ms")
        @test getattr(el3, "data-hx-swap") == "innerHTML settle:200ms"

        el4 = HTMLElement(:div)
        hxswap!(el4, "outerHTML"; ignoreTitle = true)
        @test getattr(el4, "data-hx-swap") == "outerHTML ignoreTitle:true"

        el5 = HTMLElement(:div)
        hxswap!(el5, "innerHTML"; scroll = "top")
        @test getattr(el5, "data-hx-swap") == "innerHTML scroll:top"

        el6 = HTMLElement(:div)
        hxswap!(el6, "innerHTML"; show = "bottom")
        @test getattr(el6, "data-hx-swap") == "innerHTML show:bottom"

        el7 = HTMLElement(:div)
        hxswap!(el7, "innerHTML"; focusScroll = false)
        @test getattr(el7, "data-hx-swap") == "innerHTML focus-scroll:false"
    end

    @testset "hxswap! with modifiers edge cases" begin
        # transition: false
        el = HTMLElement(:div)
        hxswap!(el, "innerHTML"; transition = false)
        @test getattr(el, "data-hx-swap") == "innerHTML transition:false"

        # ignoreTitle: false
        el2 = HTMLElement(:div)
        hxswap!(el2, "innerHTML"; ignoreTitle = false)
        @test getattr(el2, "data-hx-swap") == "innerHTML ignoreTitle:false"

        # focusScroll: true
        el3 = HTMLElement(:div)
        hxswap!(el3, "innerHTML"; focusScroll = true)
        @test getattr(el3, "data-hx-swap") == "innerHTML focus-scroll:true"

        # scroll: "bottom"
        el4 = HTMLElement(:div)
        hxswap!(el4, "innerHTML"; scroll = "bottom")
        @test getattr(el4, "data-hx-swap") == "innerHTML scroll:bottom"

        # show: "top"
        el5 = HTMLElement(:div)
        hxswap!(el5, "innerHTML"; show = "top")
        @test getattr(el5, "data-hx-swap") == "innerHTML show:top"

        # All modifiers combined
        el6 = HTMLElement(:div)
        hxswap!(el6, "outerHTML";
            transition = true,
            swap = "50ms",
            settle = "100ms",
            ignoreTitle = true,
            scroll = "top",
            show = "bottom",
            focusScroll = false)
        swap_val = getattr(el6, "data-hx-swap")
        @test startswith(swap_val, "outerHTML")
        @test occursin("transition:true", swap_val)
        @test occursin("swap:50ms", swap_val)
        @test occursin("settle:100ms", swap_val)
        @test occursin("ignoreTitle:true", swap_val)
        @test occursin("scroll:top", swap_val)
        @test occursin("show:bottom", swap_val)
        @test occursin("focus-scroll:false", swap_val)

        # No modifiers passed (all nothing/default)
        el7 = HTMLElement(:div)
        hxswap!(el7, "delete")
        @test getattr(el7, "data-hx-swap") == "delete"

        # Swap with "none" style + modifiers
        el8 = HTMLElement(:div)
        hxswap!(el8, "none"; focusScroll = false)
        @test getattr(el8, "data-hx-swap") == "none focus-scroll:false"
    end

    @testset "hxswap! with multiple modifiers" begin
        el = HTMLElement(:div)
        hxswap!(el, "outerHTML"; transition = true, swap = "100ms",
            settle = "200ms", ignoreTitle = true)
        swap_val = getattr(el, "data-hx-swap")
        @test startswith(swap_val, "outerHTML")
        @test occursin("transition:true", swap_val)
        @test occursin("swap:100ms", swap_val)
        @test occursin("settle:200ms", swap_val)
        @test occursin("ignoreTitle:true", swap_val)
    end

    @testset "hxswap! invalid style" begin
        el = HTMLElement(:div)
        @test_throws ArgumentError hxswap!(el, "invalid")
    end

    @testset "hxswap! invalid style error message" begin
        el = HTMLElement(:div)
        try
            hxswap!(el, "badstyle")
            @test false  # Should not reach here
        catch e
            @test e isa ArgumentError
            @test occursin("badstyle", e.msg)
            @test occursin("Invalid swap style", e.msg)
        end

        # Various invalid styles
        for bad in ["innerhtml", "outer", "INNERHTML", "append", "prepend", "replace"]
            el = HTMLElement(:div)
            @test_throws ArgumentError hxswap!(el, bad)
        end
    end

    # ──────────────────────────────────────────────
    # hxswapoob!
    # ──────────────────────────────────────────────
    @testset "hxswapoob!" begin
        el = HTMLElement(:div)
        result = hxswapoob!(el)
        @test result === el
        @test getattr(el, "data-hx-swap-oob") == "true"

        el2 = HTMLElement(:div)
        hxswapoob!(el2, "innerHTML:#target")
        @test getattr(el2, "data-hx-swap-oob") == "innerHTML:#target"
    end

    @testset "hxswapoob! edge cases" begin
        # Various swap styles with selectors
        el = HTMLElement(:div)
        hxswapoob!(el, "outerHTML:#notifications")
        @test getattr(el, "data-hx-swap-oob") == "outerHTML:#notifications"

        el2 = HTMLElement(:div)
        hxswapoob!(el2, "afterbegin:#messages")
        @test getattr(el2, "data-hx-swap-oob") == "afterbegin:#messages"

        el3 = HTMLElement(:div)
        hxswapoob!(el3, "beforeend:.container")
        @test getattr(el3, "data-hx-swap-oob") == "beforeend:.container"

        # Default value "true"
        el4 = HTMLElement(:span)
        hxswapoob!(el4)
        @test getattr(el4, "data-hx-swap-oob") == "true"
    end

    # ──────────────────────────────────────────────
    # hxselect! / hxselectoob!
    # ──────────────────────────────────────────────
    @testset "hxselect!" begin
        el = HTMLElement(:div)
        result = hxselect!(el, "#content")
        @test result === el
        @test getattr(el, "data-hx-select") == "#content"
    end

    @testset "hxselect! edge cases" begin
        # Complex selectors
        el = HTMLElement(:div)
        hxselect!(el, ".main-content > article:first-of-type")
        @test getattr(el, "data-hx-select") == ".main-content > article:first-of-type"

        el2 = HTMLElement(:div)
        hxselect!(el2, "table tbody tr")
        @test getattr(el2, "data-hx-select") == "table tbody tr"
    end

    @testset "hxselectoob!" begin
        el = HTMLElement(:div)
        result = hxselectoob!(el, "#info-details,#other-elt")
        @test result === el
        @test getattr(el, "data-hx-select-oob") == "#info-details,#other-elt"
    end

    @testset "hxselectoob! edge cases" begin
        # Single selector
        el = HTMLElement(:div)
        hxselectoob!(el, "#single")
        @test getattr(el, "data-hx-select-oob") == "#single"

        # Multiple comma-separated selectors
        el2 = HTMLElement(:div)
        hxselectoob!(el2, "#a,#b,#c,#d")
        @test getattr(el2, "data-hx-select-oob") == "#a,#b,#c,#d"
    end

    # ──────────────────────────────────────────────
    # hxvals!
    # ──────────────────────────────────────────────
    @testset "hxvals!" begin
        el = HTMLElement(:div)
        result = hxvals!(el, "{\"myVal\": \"test\"}")
        @test result === el
        @test getattr(el, "data-hx-vals") == "{\"myVal\": \"test\"}"
    end

    @testset "hxvals! edge cases" begin
        # Multiple values
        el = HTMLElement(:div)
        hxvals!(el, "{\"key1\": \"val1\", \"key2\": 42, \"key3\": true}")
        @test getattr(el, "data-hx-vals") ==
              "{\"key1\": \"val1\", \"key2\": 42, \"key3\": true}"

        # JS: prefix for dynamic values
        el2 = HTMLElement(:div)
        hxvals!(el2, "js:{myVal: calculateValue()}")
        @test getattr(el2, "data-hx-vals") == "js:{myVal: calculateValue()}"

        # Empty object
        el3 = HTMLElement(:div)
        hxvals!(el3, "{}")
        @test getattr(el3, "data-hx-vals") == "{}"

        # Nested JSON
        el4 = HTMLElement(:div)
        hxvals!(el4, "{\"outer\": {\"inner\": \"value\"}}")
        @test getattr(el4, "data-hx-vals") == "{\"outer\": {\"inner\": \"value\"}}"
    end

    # ──────────────────────────────────────────────
    # hxpushurl! / hxreplaceurl!
    # ──────────────────────────────────────────────
    @testset "hxpushurl!" begin
        el = HTMLElement(:a)
        result = hxpushurl!(el)
        @test result === el
        @test getattr(el, "data-hx-push-url") == "true"

        el2 = HTMLElement(:a)
        hxpushurl!(el2, "/custom-url")
        @test getattr(el2, "data-hx-push-url") == "/custom-url"

        el3 = HTMLElement(:a)
        hxpushurl!(el3, "false")
        @test getattr(el3, "data-hx-push-url") == "false"
    end

    @testset "hxpushurl! edge cases" begin
        # URL with query params
        el = HTMLElement(:a)
        hxpushurl!(el, "/search?q=test&page=2")
        @test getattr(el, "data-hx-push-url") == "/search?q=test&page=2"

        # Full URL
        el2 = HTMLElement(:a)
        hxpushurl!(el2, "https://example.com/page")
        @test getattr(el2, "data-hx-push-url") == "https://example.com/page"
    end

    @testset "hxreplaceurl!" begin
        el = HTMLElement(:a)
        result = hxreplaceurl!(el)
        @test result === el
        @test getattr(el, "data-hx-replace-url") == "true"

        el2 = HTMLElement(:a)
        hxreplaceurl!(el2, "/new-url")
        @test getattr(el2, "data-hx-replace-url") == "/new-url"
    end

    @testset "hxreplaceurl! edge cases" begin
        # "false" value
        el = HTMLElement(:a)
        hxreplaceurl!(el, "false")
        @test getattr(el, "data-hx-replace-url") == "false"

        # Custom URL with hash
        el2 = HTMLElement(:a)
        hxreplaceurl!(el2, "/page#section")
        @test getattr(el2, "data-hx-replace-url") == "/page#section"
    end

    # ──────────────────────────────────────────────
    # hxconfirm! / hxprompt!
    # ──────────────────────────────────────────────
    @testset "hxconfirm!" begin
        el = HTMLElement(:button)
        result = hxconfirm!(el, "Are you sure?")
        @test result === el
        @test getattr(el, "data-hx-confirm") == "Are you sure?"
    end

    @testset "hxconfirm! edge cases" begin
        # Long message with special characters
        el = HTMLElement(:button)
        hxconfirm!(el, "Delete item #42? This can't be undone & will remove all data.")
        @test getattr(el, "data-hx-confirm") ==
              "Delete item #42? This can't be undone & will remove all data."

        # Multilingual message
        el2 = HTMLElement(:button)
        hxconfirm!(el2, "Voulez-vous continuer?")
        @test getattr(el2, "data-hx-confirm") == "Voulez-vous continuer?"
    end

    @testset "hxprompt!" begin
        el = HTMLElement(:button)
        result = hxprompt!(el, "Enter a value")
        @test result === el
        @test getattr(el, "data-hx-prompt") == "Enter a value"
    end

    @testset "hxprompt! edge cases" begin
        # Message with special characters
        el = HTMLElement(:button)
        hxprompt!(el, "Enter your name (first & last):")
        @test getattr(el, "data-hx-prompt") == "Enter your name (first & last):"
    end

    # ──────────────────────────────────────────────
    # hxindicator!
    # ──────────────────────────────────────────────
    @testset "hxindicator!" begin
        el = HTMLElement(:button)
        result = hxindicator!(el, "#spinner")
        @test result === el
        @test getattr(el, "data-hx-indicator") == "#spinner"
    end

    @testset "hxindicator! edge cases" begin
        # Various CSS selectors
        el = HTMLElement(:div)
        hxindicator!(el, ".loading-spinner")
        @test getattr(el, "data-hx-indicator") == ".loading-spinner"

        el2 = HTMLElement(:div)
        hxindicator!(el2, "closest .indicator")
        @test getattr(el2, "data-hx-indicator") == "closest .indicator"
    end

    # ──────────────────────────────────────────────
    # hxboost!
    # ──────────────────────────────────────────────
    @testset "hxboost!" begin
        el = HTMLElement(:div)
        result = hxboost!(el)
        @test result === el
        @test getattr(el, "data-hx-boost") == "true"

        el2 = HTMLElement(:div)
        hxboost!(el2, "false")
        @test getattr(el2, "data-hx-boost") == "false"
    end

    @testset "hxboost! edge cases" begin
        # On various semantic elements
        for tag_sym in [:nav, :main, :section, :article, :div]
            el = HTMLElement(tag_sym)
            hxboost!(el)
            @test getattr(el, "data-hx-boost") == "true"
        end
    end

    # ──────────────────────────────────────────────
    # hxinclude! / hxparams!
    # ──────────────────────────────────────────────
    @testset "hxinclude!" begin
        el = HTMLElement(:div)
        result = hxinclude!(el, "[name='email']")
        @test result === el
        @test getattr(el, "data-hx-include") == "[name='email']"
    end

    @testset "hxinclude! edge cases" begin
        # Various selector types
        el = HTMLElement(:div)
        hxinclude!(el, "#other-form")
        @test getattr(el, "data-hx-include") == "#other-form"

        el2 = HTMLElement(:div)
        hxinclude!(el2, "this")
        @test getattr(el2, "data-hx-include") == "this"

        el3 = HTMLElement(:div)
        hxinclude!(el3, "closest form")
        @test getattr(el3, "data-hx-include") == "closest form"
    end

    @testset "hxparams!" begin
        el = HTMLElement(:div)
        result = hxparams!(el, "*")
        @test result === el
        @test getattr(el, "data-hx-params") == "*"

        el2 = HTMLElement(:div)
        hxparams!(el2, "none")
        @test getattr(el2, "data-hx-params") == "none"

        el3 = HTMLElement(:div)
        hxparams!(el3, "not secret")
        @test getattr(el3, "data-hx-params") == "not secret"
    end

    @testset "hxparams! edge cases" begin
        # Comma-separated parameter list
        el = HTMLElement(:div)
        hxparams!(el, "name,email,age")
        @test getattr(el, "data-hx-params") == "name,email,age"

        # "not" with multiple excluded params
        el2 = HTMLElement(:div)
        hxparams!(el2, "not secret,token,password")
        @test getattr(el2, "data-hx-params") == "not secret,token,password"
    end

    # ──────────────────────────────────────────────
    # hxheaders!
    # ──────────────────────────────────────────────
    @testset "hxheaders!" begin
        el = HTMLElement(:div)
        result = hxheaders!(el, "{\"X-CSRF-Token\": \"abc123\"}")
        @test result === el
        @test getattr(el, "data-hx-headers") == "{\"X-CSRF-Token\": \"abc123\"}"
    end

    @testset "hxheaders! edge cases" begin
        # Multiple headers
        el = HTMLElement(:div)
        hxheaders!(el, "{\"Authorization\": \"Bearer token123\", \"X-Custom\": \"value\"}")
        @test getattr(el, "data-hx-headers") ==
              "{\"Authorization\": \"Bearer token123\", \"X-Custom\": \"value\"}"

        # JS: prefix for dynamic headers
        el2 = HTMLElement(:div)
        hxheaders!(el2, "js:{\"X-Token\": getToken()}")
        @test getattr(el2, "data-hx-headers") == "js:{\"X-Token\": getToken()}"

        # Empty headers
        el3 = HTMLElement(:div)
        hxheaders!(el3, "{}")
        @test getattr(el3, "data-hx-headers") == "{}"
    end

    # ──────────────────────────────────────────────
    # hxsync!
    # ──────────────────────────────────────────────
    @testset "hxsync!" begin
        el = HTMLElement(:input)
        result = hxsync!(el, "closest form:abort")
        @test result === el
        @test getattr(el, "data-hx-sync") == "closest form:abort"

        el2 = HTMLElement(:div)
        hxsync!(el2, "this:drop")
        @test getattr(el2, "data-hx-sync") == "this:drop"

        el3 = HTMLElement(:div)
        hxsync!(el3, "this:queue last")
        @test getattr(el3, "data-hx-sync") == "this:queue last"
    end

    @testset "hxsync! edge cases" begin
        # All sync strategies
        for strategy in ["this:drop", "this:abort", "this:replace",
            "this:queue first", "this:queue last", "this:queue all"]
            el = HTMLElement(:div)
            hxsync!(el, strategy)
            @test getattr(el, "data-hx-sync") == strategy
        end

        # Closest with selector
        el = HTMLElement(:div)
        hxsync!(el, "closest div:replace")
        @test getattr(el, "data-hx-sync") == "closest div:replace"
    end

    # ──────────────────────────────────────────────
    # hxencoding!
    # ──────────────────────────────────────────────
    @testset "hxencoding!" begin
        el = HTMLElement(:form)
        result = hxencoding!(el)
        @test result === el
        @test getattr(el, "data-hx-encoding") == "multipart/form-data"

        el2 = HTMLElement(:form)
        hxencoding!(el2, "application/x-www-form-urlencoded")
        @test getattr(el2, "data-hx-encoding") == "application/x-www-form-urlencoded"
    end

    @testset "hxencoding! edge cases" begin
        # Default value via no-arg
        el = HTMLElement(:form)
        hxencoding!(el)
        @test getattr(el, "data-hx-encoding") == "multipart/form-data"
    end

    # ──────────────────────────────────────────────
    # hxext!
    # ──────────────────────────────────────────────
    @testset "hxext!" begin
        el = HTMLElement(:body)
        result = hxext!(el, "response-targets")
        @test result === el
        @test getattr(el, "data-hx-ext") == "response-targets"

        el2 = HTMLElement(:div)
        hxext!(el2, "ignore:response-targets")
        @test getattr(el2, "data-hx-ext") == "ignore:response-targets"

        el3 = HTMLElement(:body)
        hxext!(el3, "response-targets,head-support")
        @test getattr(el3, "data-hx-ext") == "response-targets,head-support"
    end

    @testset "hxext! edge cases" begin
        # Single extension
        for ext in ["json-enc", "morphdom-swap", "alpine-morph",
            "class-tools", "loading-states", "path-deps",
            "multi-swap", "restored", "sse", "ws"]
            el = HTMLElement(:body)
            hxext!(el, ext)
            @test getattr(el, "data-hx-ext") == ext
        end

        # Multiple ignore
        el = HTMLElement(:div)
        hxext!(el, "ignore:sse,ignore:ws")
        @test getattr(el, "data-hx-ext") == "ignore:sse,ignore:ws"
    end

    # ──────────────────────────────────────────────
    # hxon!
    # ──────────────────────────────────────────────
    @testset "hxon!" begin
        el = HTMLElement(:button)
        result = hxon!(el, "click", "alert('clicked')")
        @test result === el
        @test getattr(el, "data-hx-on:click") == "alert('clicked')"

        el2 = HTMLElement(:button)
        hxon!(el2, "htmx:before-request", "console.log('requesting')")
        @test getattr(el2, "data-hx-on:htmx:before-request") == "console.log('requesting')"

        el3 = HTMLElement(:button)
        hxon!(el3, "htmx:config-request", "event.detail.parameters.example = 'Hello'")
        @test getattr(el3, "data-hx-on:htmx:config-request") ==
              "event.detail.parameters.example = 'Hello'"
    end

    @testset "hxon! edge cases" begin
        # Multiple event handlers on same element
        el = HTMLElement(:button)
        hxon!(el, "click", "handleClick()")
        hxon!(el, "mouseenter", "handleHover()")
        @test getattr(el, "data-hx-on:click") == "handleClick()"
        @test getattr(el, "data-hx-on:mouseenter") == "handleHover()"

        # htmx lifecycle events
        for event in ["htmx:before-request", "htmx:after-request",
            "htmx:before-swap", "htmx:after-swap",
            "htmx:before-settle", "htmx:after-settle",
            "htmx:load", "htmx:xhr:loadend"]
            el = HTMLElement(:div)
            hxon!(el, event, "console.log('event')")
            @test getattr(el, "data-hx-on:$event") == "console.log('event')"
        end

        # Multi-line script
        el2 = HTMLElement(:form)
        script = "if (event.detail.successful) { alert('Success!'); } else { alert('Failed'); }"
        hxon!(el2, "htmx:after-request", script)
        @test getattr(el2, "data-hx-on:htmx:after-request") == script

        # Standard DOM events
        for event in ["click", "dblclick", "mousedown", "mouseup",
            "keydown", "keyup", "keypress", "submit",
            "change", "input", "focus", "blur"]
            el = HTMLElement(:div)
            hxon!(el, event, "handler()")
            @test getattr(el, "data-hx-on:$event") == "handler()"
        end
    end

    # ──────────────────────────────────────────────
    # hxdisable! / hxdisabledelt!
    # ──────────────────────────────────────────────
    @testset "hxdisable!" begin
        el = HTMLElement(:div)
        result = hxdisable!(el)
        @test result === el
        @test hasattr(el, "data-hx-disable")
    end

    @testset "hxdisable! edge cases" begin
        # Verify the value is empty string
        el = HTMLElement(:div)
        hxdisable!(el)
        @test getattr(el, "data-hx-disable") == ""

        # Can be applied to any element type
        for tag_sym in [:div, :form, :section, :article, :span]
            el = HTMLElement(tag_sym)
            hxdisable!(el)
            @test hasattr(el, "data-hx-disable")
            @test getattr(el, "data-hx-disable") == ""
        end
    end

    @testset "hxdisabledelt!" begin
        el = HTMLElement(:form)
        result = hxdisabledelt!(el, "this")
        @test result === el
        @test getattr(el, "data-hx-disabled-elt") == "this"

        el2 = HTMLElement(:form)
        hxdisabledelt!(el2, "closest button")
        @test getattr(el2, "data-hx-disabled-elt") == "closest button"
    end

    @testset "hxdisabledelt! edge cases" begin
        # Various selectors
        el = HTMLElement(:form)
        hxdisabledelt!(el, "#submit-btn")
        @test getattr(el, "data-hx-disabled-elt") == "#submit-btn"

        el2 = HTMLElement(:form)
        hxdisabledelt!(el2, "find button")
        @test getattr(el2, "data-hx-disabled-elt") == "find button"

        # Multiple selectors (comma separated)
        el3 = HTMLElement(:form)
        hxdisabledelt!(el3, "#btn1, #btn2")
        @test getattr(el3, "data-hx-disabled-elt") == "#btn1, #btn2"
    end

    # ──────────────────────────────────────────────
    # hxdisinherit! / hxinherit!
    # ──────────────────────────────────────────────
    @testset "hxdisinherit!" begin
        el = HTMLElement(:div)
        result = hxdisinherit!(el, "*")
        @test result === el
        @test getattr(el, "data-hx-disinherit") == "*"

        el2 = HTMLElement(:div)
        hxdisinherit!(el2, "hx-target hx-swap")
        @test getattr(el2, "data-hx-disinherit") == "hx-target hx-swap"
    end

    @testset "hxdisinherit! edge cases" begin
        # Single attribute
        el = HTMLElement(:div)
        hxdisinherit!(el, "hx-get")
        @test getattr(el, "data-hx-disinherit") == "hx-get"

        # Multiple attributes
        el2 = HTMLElement(:div)
        hxdisinherit!(el2, "hx-target hx-swap hx-trigger hx-vals")
        @test getattr(el2, "data-hx-disinherit") == "hx-target hx-swap hx-trigger hx-vals"
    end

    @testset "hxinherit!" begin
        el = HTMLElement(:div)
        result = hxinherit!(el, "*")
        @test result === el
        @test getattr(el, "data-hx-inherit") == "*"

        el2 = HTMLElement(:div)
        hxinherit!(el2, "hx-target hx-swap")
        @test getattr(el2, "data-hx-inherit") == "hx-target hx-swap"
    end

    @testset "hxinherit! edge cases" begin
        # Single attribute
        el = HTMLElement(:div)
        hxinherit!(el, "hx-get")
        @test getattr(el, "data-hx-inherit") == "hx-get"
    end

    # ──────────────────────────────────────────────
    # hxhistory! / hxhistoryelt!
    # ──────────────────────────────────────────────
    @testset "hxhistory!" begin
        el = HTMLElement(:div)
        result = hxhistory!(el)
        @test result === el
        @test getattr(el, "data-hx-history") == "false"

        el2 = HTMLElement(:div)
        hxhistory!(el2, "true")
        @test getattr(el2, "data-hx-history") == "true"
    end

    @testset "hxhistory! edge cases" begin
        # Default value is "false"
        el = HTMLElement(:body)
        hxhistory!(el)
        @test getattr(el, "data-hx-history") == "false"
    end

    @testset "hxhistoryelt!" begin
        el = HTMLElement(:div)
        result = hxhistoryelt!(el)
        @test result === el
        @test hasattr(el, "data-hx-history-elt")
    end

    @testset "hxhistoryelt! edge cases" begin
        # Verify empty string value
        el = HTMLElement(:div)
        hxhistoryelt!(el)
        @test getattr(el, "data-hx-history-elt") == ""

        # Applied to main content element
        el2 = HTMLElement(:main)
        hxhistoryelt!(el2)
        @test hasattr(el2, "data-hx-history-elt")
    end

    # ──────────────────────────────────────────────
    # hxpreserve!
    # ──────────────────────────────────────────────
    @testset "hxpreserve!" begin
        el = HTMLElement(:div)
        result = hxpreserve!(el)
        @test result === el
        @test hasattr(el, "data-hx-preserve")
    end

    @testset "hxpreserve! edge cases" begin
        # Verify empty string value
        el = HTMLElement(:div)
        hxpreserve!(el)
        @test getattr(el, "data-hx-preserve") == ""

        # Typical usage: video/audio elements
        el2 = HTMLElement(:video)
        el2["id"] = "main-video"
        hxpreserve!(el2)
        @test hasattr(el2, "data-hx-preserve")
        @test getattr(el2, "id") == "main-video"
    end

    # ──────────────────────────────────────────────
    # hxrequestconfig!
    # ──────────────────────────────────────────────
    @testset "hxrequestconfig!" begin
        el = HTMLElement(:div)
        result = hxrequestconfig!(el, "timeout:3000")
        @test result === el
        @test getattr(el, "data-hx-request") == "timeout:3000"

        el2 = HTMLElement(:div)
        hxrequestconfig!(el2, "credentials:true")
        @test getattr(el2, "data-hx-request") == "credentials:true"

        el3 = HTMLElement(:div)
        hxrequestconfig!(el3, "noHeaders:true")
        @test getattr(el3, "data-hx-request") == "noHeaders:true"
    end

    @testset "hxrequestconfig! edge cases" begin
        # Multiple config values
        el = HTMLElement(:div)
        hxrequestconfig!(el, "timeout:5000, credentials:true")
        @test getattr(el, "data-hx-request") == "timeout:5000, credentials:true"

        # JSON-style config
        el2 = HTMLElement(:div)
        hxrequestconfig!(el2, "{\"timeout\": 10000}")
        @test getattr(el2, "data-hx-request") == "{\"timeout\": 10000}"
    end

    # ──────────────────────────────────────────────
    # hxvalidate!
    # ──────────────────────────────────────────────
    @testset "hxvalidate!" begin
        el = HTMLElement(:div)
        result = hxvalidate!(el)
        @test result === el
        @test getattr(el, "data-hx-validate") == "true"
    end

    @testset "hxvalidate! edge cases" begin
        # On form element
        el = HTMLElement(:form)
        hxvalidate!(el)
        @test getattr(el, "data-hx-validate") == "true"

        # On input element
        el2 = HTMLElement(:input)
        hxvalidate!(el2)
        @test getattr(el2, "data-hx-validate") == "true"
    end

    # ══════════════════════════════════════════════
    # Combined / Integration tests
    # ══════════════════════════════════════════════
    @testset "combined hx attributes" begin
        el = HTMLElement(:button)
        hxget!(el, "/api/data")
        hxtrigger!(el, "click"; once = true)
        @test getattr(el, "data-hx-get") == "/api/data"
        @test getattr(el, "data-hx-trigger") == "click once"
    end

    @testset "full htmx example: active search" begin
        el = HTMLElement(:input)
        hxget!(el, "/search")
        hxtrigger!(el, "keyup"; changed = true, delay = "500ms")
        hxtarget!(el, "#search-results")
        hxindicator!(el, ".htmx-indicator")
        @test getattr(el, "data-hx-get") == "/search"
        @test getattr(el, "data-hx-trigger") == "keyup changed delay:500ms"
        @test getattr(el, "data-hx-target") == "#search-results"
        @test getattr(el, "data-hx-indicator") == ".htmx-indicator"
    end

    @testset "full htmx example: delete with confirm" begin
        el = HTMLElement(:button)
        hxdelete!(el, "/account")
        hxconfirm!(el, "Are you sure you wish to delete your account?")
        hxswap!(el, "outerHTML")
        @test getattr(el, "data-hx-delete") == "/account"
        @test getattr(el, "data-hx-confirm") ==
              "Are you sure you wish to delete your account?"
        @test getattr(el, "data-hx-swap") == "outerHTML"
    end

    @testset "full htmx example: boosted navigation" begin
        el = HTMLElement(:div)
        hxboost!(el)
        @test getattr(el, "data-hx-boost") == "true"
    end

    @testset "full htmx example: form with sync" begin
        input = HTMLElement(:input)
        hxpost!(input, "/validate")
        hxtrigger!(input, "change")
        hxsync!(input, "closest form:abort")
        @test getattr(input, "data-hx-post") == "/validate"
        @test getattr(input, "data-hx-trigger") == "change"
        @test getattr(input, "data-hx-sync") == "closest form:abort"
    end

    @testset "full htmx example: history push" begin
        el = HTMLElement(:a)
        hxget!(el, "/blog")
        hxpushurl!(el)
        @test getattr(el, "data-hx-get") == "/blog"
        @test getattr(el, "data-hx-push-url") == "true"
    end

    @testset "full htmx example: file upload" begin
        el = HTMLElement(:form)
        hxpost!(el, "/upload")
        hxencoding!(el)
        @test getattr(el, "data-hx-post") == "/upload"
        @test getattr(el, "data-hx-encoding") == "multipart/form-data"
    end

    @testset "full htmx example: CSRF headers" begin
        el = HTMLElement(:body)
        hxheaders!(el, "{\"X-CSRF-TOKEN\": \"abc123\"}")
        @test getattr(el, "data-hx-headers") == "{\"X-CSRF-TOKEN\": \"abc123\"}"
    end

    @testset "full htmx example: with extensions" begin
        el = HTMLElement(:body)
        hxext!(el, "response-targets")
        @test getattr(el, "data-hx-ext") == "response-targets"
    end

    @testset "full htmx example: inline event handler" begin
        el = HTMLElement(:button)
        hxpost!(el, "/example")
        hxon!(el, "htmx:config-request", "event.detail.parameters.example = 'Hello'")
        @test getattr(el, "data-hx-post") == "/example"
        @test getattr(el, "data-hx-on:htmx:config-request") ==
              "event.detail.parameters.example = 'Hello'"
    end

    @testset "full htmx example: out of band swap" begin
        el = HTMLElement(:div)
        el["id"] = "message"
        hxswapoob!(el)
        @test getattr(el, "id") == "message"
        @test getattr(el, "data-hx-swap-oob") == "true"
    end

    # ══════════════════════════════════════════════
    # Advanced integration / edge case scenarios
    # ══════════════════════════════════════════════
    @testset "attribute overwrite: calling same setter twice" begin
        el = HTMLElement(:button)
        hxget!(el, "/first")
        @test getattr(el, "data-hx-get") == "/first"
        hxget!(el, "/second")
        @test getattr(el, "data-hx-get") == "/second"

        el2 = HTMLElement(:div)
        hxtarget!(el2, "#old")
        hxtarget!(el2, "#new")
        @test getattr(el2, "data-hx-target") == "#new"

        el3 = HTMLElement(:div)
        hxswap!(el3, "innerHTML")
        hxswap!(el3, "outerHTML")
        @test getattr(el3, "data-hx-swap") == "outerHTML"
    end

    @testset "element with many htmx attributes" begin
        el = HTMLElement(:button)
        hxpost!(el, "/submit")
        hxtrigger!(el, "click"; once = true)
        hxtarget!(el, "#result")
        hxswap!(el, "outerHTML"; transition = true)
        hxconfirm!(el, "Submit?")
        hxindicator!(el, "#loading")
        hxvals!(el, "{\"extra\": \"data\"}")
        hxheaders!(el, "{\"X-Custom\": \"val\"}")
        hxsync!(el, "closest form:abort")
        hxdisabledelt!(el, "this")
        hxon!(el, "htmx:before-request", "showLoader()")
        hxon!(el, "htmx:after-request", "hideLoader()")

        @test getattr(el, "data-hx-post") == "/submit"
        @test getattr(el, "data-hx-trigger") == "click once"
        @test getattr(el, "data-hx-target") == "#result"
        @test occursin("outerHTML", getattr(el, "data-hx-swap"))
        @test occursin("transition:true", getattr(el, "data-hx-swap"))
        @test getattr(el, "data-hx-confirm") == "Submit?"
        @test getattr(el, "data-hx-indicator") == "#loading"
        @test getattr(el, "data-hx-vals") == "{\"extra\": \"data\"}"
        @test getattr(el, "data-hx-headers") == "{\"X-Custom\": \"val\"}"
        @test getattr(el, "data-hx-sync") == "closest form:abort"
        @test getattr(el, "data-hx-disabled-elt") == "this"
        @test getattr(el, "data-hx-on:htmx:before-request") == "showLoader()"
        @test getattr(el, "data-hx-on:htmx:after-request") == "hideLoader()"
    end

    @testset "mixing htmx and regular HTML attributes" begin
        el = HTMLElement(:button)
        el["id"] = "my-btn"
        el["class"] = "btn btn-primary"
        el["type"] = "button"
        el["disabled"] = "true"
        hxget!(el, "/api/data")
        hxtrigger!(el, "click")
        hxtarget!(el, "#output")

        @test getattr(el, "id") == "my-btn"
        @test getattr(el, "class") == "btn btn-primary"
        @test getattr(el, "type") == "button"
        @test getattr(el, "disabled") == "true"
        @test getattr(el, "data-hx-get") == "/api/data"
        @test getattr(el, "data-hx-trigger") == "click"
        @test getattr(el, "data-hx-target") == "#output"
    end

    @testset "fluent API: chaining returns" begin
        # Verify all mutating functions return the element for chaining
        el = HTMLElement(:button)
        @test hxget!(el, "/a") === el
        @test hxpost!(el, "/b") === el
        @test hxput!(el, "/c") === el
        @test hxpatch!(el, "/d") === el
        @test hxdelete!(el, "/e") === el
        @test hxattr!(el, "custom", "val") === el
        @test hxrequest!(el, :get, "/f") === el
        @test hxtrigger!(el, "click") === el
        @test hxtarget!(el, "#t") === el
        @test hxswap!(el, "innerHTML") === el
        @test hxswapoob!(el) === el
        @test hxselect!(el, "#s") === el
        @test hxselectoob!(el, "#so") === el
        @test hxvals!(el, "{}") === el
        @test hxpushurl!(el) === el
        @test hxreplaceurl!(el) === el
        @test hxconfirm!(el, "?") === el
        @test hxprompt!(el, "?") === el
        @test hxindicator!(el, "#i") === el
        @test hxboost!(el) === el
        @test hxinclude!(el, "#inc") === el
        @test hxparams!(el, "*") === el
        @test hxheaders!(el, "{}") === el
        @test hxsync!(el, "this:drop") === el
        @test hxencoding!(el) === el
        @test hxext!(el, "ext") === el
        @test hxon!(el, "click", "fn()") === el
        @test hxdisable!(el) === el
        @test hxdisabledelt!(el, "this") === el
        @test hxdisinherit!(el, "*") === el
        @test hxinherit!(el, "*") === el
        @test hxhistory!(el) === el
        @test hxhistoryelt!(el) === el
        @test hxpreserve!(el) === el
        @test hxrequestconfig!(el, "timeout:1000") === el
        @test hxvalidate!(el) === el
    end

    @testset "rendering htmx element to string" begin
        el = HTMLElement(:button)
        hxget!(el, "/api/data")
        hxtrigger!(el, "click")
        hxtarget!(el, "#result")
        hxswap!(el, "innerHTML")

        html = sprint(print, el)
        @test occursin("<button", html)
        @test occursin("</button>", html)
        @test occursin("data-hx-get=\"/api/data\"", html)
        @test occursin("data-hx-trigger=\"click\"", html)
        @test occursin("data-hx-target=\"#result\"", html)
        @test occursin("data-hx-swap=\"innerHTML\"", html)
    end

    @testset "rendering htmx element with entity encoding" begin
        el = HTMLElement(:div)
        hxconfirm!(el, "Are you sure? It's a \"big\" deal & final.")
        html = sprint(print, el)
        # Attributes should have entities encoded
        @test occursin("data-hx-confirm=", html)
        @test occursin("&amp;", html)
        @test occursin("&quot;", html)
        @test occursin("&#39;", html)
    end

    @testset "rendering htmx element prettyprint" begin
        el = HTMLElement(:div)
        hxget!(el, "/api")
        hxtarget!(el, "#out")
        child = HTMLElement(:span)
        push!(el, child)

        buf = IOBuffer()
        prettyprint(buf, el)
        html = String(take!(buf))
        @test occursin("data-hx-get=\"/api\"", html)
        @test occursin("data-hx-target=\"#out\"", html)
        @test occursin("<span>", html)
    end

    @testset "htmx on void/self-closing elements" begin
        # input is a void element
        el = HTMLElement(:input)
        hxget!(el, "/search")
        hxtrigger!(el, "keyup"; delay = "300ms")
        html = sprint(print, el)
        @test occursin("<input", html)
        @test occursin("/>", html)
        @test occursin("data-hx-get=\"/search\"", html)
        @test !occursin("</input>", html)

        # img element
        el2 = HTMLElement(:img)
        hxget!(el2, "/lazy-image")
        load_trigger(el2)
        html2 = sprint(print, el2)
        @test occursin("<img", html2)
        @test occursin("/>", html2)
    end

    @testset "htmx with text content child" begin
        el = HTMLElement(:button)
        push!(el, HTMLText("Click me"))
        hxpost!(el, "/action")
        hxtrigger!(el, "click")

        html = sprint(print, el)
        @test occursin("Click me", html)
        @test occursin("data-hx-post=\"/action\"", html)
        @test occursin("data-hx-trigger=\"click\"", html)
    end

    @testset "full htmx example: infinite scroll" begin
        el = HTMLElement(:div)
        hxget!(el, "/api/items?page=2")
        hxtrigger!(el, "revealed")
        hxswap!(el, "afterend")
        hxindicator!(el, "#load-more-spinner")

        @test getattr(el, "data-hx-get") == "/api/items?page=2"
        @test getattr(el, "data-hx-trigger") == "revealed"
        @test getattr(el, "data-hx-swap") == "afterend"
        @test getattr(el, "data-hx-indicator") == "#load-more-spinner"
    end

    @testset "full htmx example: lazy loading" begin
        el = HTMLElement(:div)
        hxget!(el, "/lazy-content")
        load_trigger(el)
        hxswap!(el, "outerHTML")

        @test getattr(el, "data-hx-get") == "/lazy-content"
        @test getattr(el, "data-hx-trigger") == "load"
        @test getattr(el, "data-hx-swap") == "outerHTML"
    end

    @testset "full htmx example: click to edit" begin
        # Display mode
        display = HTMLElement(:div)
        hxget!(display, "/contact/1/edit")
        hxtrigger!(display, "click")
        hxswap!(display, "outerHTML")

        @test getattr(display, "data-hx-get") == "/contact/1/edit"
        @test getattr(display, "data-hx-trigger") == "click"
        @test getattr(display, "data-hx-swap") == "outerHTML"
    end

    @testset "full htmx example: inline validation" begin
        el = HTMLElement(:input)
        el["name"] = "email"
        el["type"] = "email"
        hxpost!(el, "/validate/email")
        hxtrigger!(el, "change"; delay = "200ms")
        hxtarget!(el, "next .error-message")
        hxswap!(el, "outerHTML")

        @test getattr(el, "name") == "email"
        @test getattr(el, "data-hx-post") == "/validate/email"
        @test getattr(el, "data-hx-trigger") == "change delay:200ms"
        @test getattr(el, "data-hx-target") == "next .error-message"
    end

    @testset "full htmx example: SSE and WebSocket-like pattern" begin
        # SSE extension
        el = HTMLElement(:div)
        hxext!(el, "sse")
        hxattr!(el, "sse-connect", "/events")
        @test getattr(el, "data-hx-ext") == "sse"
        @test getattr(el, "data-hx-sse-connect") == "/events"

        # WS extension pattern
        el2 = HTMLElement(:div)
        hxext!(el2, "ws")
        hxattr!(el2, "ws-connect", "/ws")
        @test getattr(el2, "data-hx-ext") == "ws"
        @test getattr(el2, "data-hx-ws-connect") == "/ws"
    end

    @testset "full htmx example: tabs pattern" begin
        tab1 = HTMLElement(:button)
        hxget!(tab1, "/tab/1")
        hxtarget!(tab1, "#tab-content")
        hxswap!(tab1, "innerHTML")

        tab2 = HTMLElement(:button)
        hxget!(tab2, "/tab/2")
        hxtarget!(tab2, "#tab-content")
        hxswap!(tab2, "innerHTML")

        @test getattr(tab1, "data-hx-get") == "/tab/1"
        @test getattr(tab2, "data-hx-get") == "/tab/2"
        @test getattr(tab1, "data-hx-target") == getattr(tab2, "data-hx-target")
    end

    @testset "full htmx example: modal dialog" begin
        trigger = HTMLElement(:button)
        hxget!(trigger, "/modal/confirm")
        hxtarget!(trigger, "#modals-here")
        hxswap!(trigger, "beforeend")

        @test getattr(trigger, "data-hx-get") == "/modal/confirm"
        @test getattr(trigger, "data-hx-target") == "#modals-here"
        @test getattr(trigger, "data-hx-swap") == "beforeend"
    end

    @testset "full htmx example: progress bar polling" begin
        el = HTMLElement(:div)
        hxget!(el, "/job/123/progress")
        poll_trigger(el, "600ms")
        hxtarget!(el, "this")
        hxswap!(el, "outerHTML")

        @test getattr(el, "data-hx-get") == "/job/123/progress"
        @test getattr(el, "data-hx-trigger") == "every 600ms"
        @test getattr(el, "data-hx-target") == "this"
        @test getattr(el, "data-hx-swap") == "outerHTML"
    end

    @testset "full htmx example: cascading selects" begin
        country = HTMLElement(:select)
        country["name"] = "country"
        hxget!(country, "/api/states")
        hxtrigger!(country, "change")
        hxtarget!(country, "#state-select")
        hxswap!(country, "outerHTML")
        hxinclude!(country, "this")

        @test getattr(country, "data-hx-get") == "/api/states"
        @test getattr(country, "data-hx-trigger") == "change"
        @test getattr(country, "data-hx-target") == "#state-select"
        @test getattr(country, "data-hx-include") == "this"
    end

    @testset "full htmx example: form with all features" begin
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

        @test getattr(form, "data-hx-post") == "/api/contacts"
        @test getattr(form, "data-hx-trigger") == "submit"
        @test getattr(form, "data-hx-target") == "#contact-list"
        swap_val = getattr(form, "data-hx-swap")
        @test occursin("beforeend", swap_val)
        @test occursin("settle:500ms", swap_val)
        @test getattr(form, "data-hx-indicator") == "#form-spinner"
        @test getattr(form, "data-hx-validate") == "true"
        @test getattr(form, "data-hx-confirm") == "Add this contact?"
        @test getattr(form, "data-hx-encoding") == "multipart/form-data"
        @test getattr(form, "data-hx-headers") == "{\"X-CSRF\": \"token\"}"
        @test getattr(form, "data-hx-disabled-elt") == "find button"
    end

    @testset "full htmx example: inheritance control" begin
        parent = HTMLElement(:div)
        hxboost!(parent)
        hxtarget!(parent, "#content")

        # Child disables inheritance
        child = HTMLElement(:div)
        hxdisinherit!(child, "hx-target")
        push!(parent, child)

        @test getattr(parent, "data-hx-boost") == "true"
        @test getattr(parent, "data-hx-target") == "#content"
        @test getattr(child, "data-hx-disinherit") == "hx-target"
    end

    @testset "full htmx example: history and preserve" begin
        # Page container with history settings
        body = HTMLElement(:body)
        hxhistory!(body, "false")  # sensitive page, no caching

        # Video that should persist across swaps
        video = HTMLElement(:video)
        video["id"] = "bg-video"
        hxpreserve!(video)

        # Navigate link
        link = HTMLElement(:a)
        hxget!(link, "/page/2")
        hxpushurl!(link, "/page/2")
        hxtarget!(link, "#main")
        hxswap!(link, "innerHTML"; transition = true)

        @test getattr(body, "data-hx-history") == "false"
        @test hasattr(video, "data-hx-preserve")
        @test getattr(link, "data-hx-get") == "/page/2"
        @test getattr(link, "data-hx-push-url") == "/page/2"
    end

    @testset "full htmx example: disabled content area" begin
        # User-generated content area where htmx should be disabled
        ugc = HTMLElement(:div)
        ugc["class"] = "user-content"
        hxdisable!(ugc)

        @test hasattr(ugc, "data-hx-disable")
        @test getattr(ugc, "class") == "user-content"
    end

    @testset "full htmx example: request config with indicator" begin
        el = HTMLElement(:div)
        hxget!(el, "/slow-endpoint")
        hxrequestconfig!(el, "timeout:30000")
        hxindicator!(el, "#long-loading")
        load_trigger(el; delay = "100ms")

        @test getattr(el, "data-hx-get") == "/slow-endpoint"
        @test getattr(el, "data-hx-request") == "timeout:30000"
        @test getattr(el, "data-hx-indicator") == "#long-loading"
        @test getattr(el, "data-hx-trigger") == "load delay:100ms"
    end

    @testset "full htmx example: select-oob multi-target update" begin
        el = HTMLElement(:button)
        hxget!(el, "/notifications")
        hxselect!(el, "#notification-list")
        hxselectoob!(el, "#notification-count,#notification-badge")
        hxtarget!(el, "#main-notifications")

        @test getattr(el, "data-hx-get") == "/notifications"
        @test getattr(el, "data-hx-select") == "#notification-list"
        @test getattr(el, "data-hx-select-oob") == "#notification-count,#notification-badge"
        @test getattr(el, "data-hx-target") == "#main-notifications"
    end

    @testset "full htmx example: prompt for user input" begin
        el = HTMLElement(:button)
        hxdelete!(el, "/items/42")
        hxprompt!(el, "Type 'DELETE' to confirm")
        hxswap!(el, "delete")

        @test getattr(el, "data-hx-delete") == "/items/42"
        @test getattr(el, "data-hx-prompt") == "Type 'DELETE' to confirm"
        @test getattr(el, "data-hx-swap") == "delete"
    end

    @testset "full htmx example: replace-url navigation" begin
        el = HTMLElement(:a)
        hxget!(el, "/page/3")
        hxreplaceurl!(el, "/page/3")
        hxtarget!(el, "#content")
        hxswap!(el, "innerHTML"; transition = true)

        @test getattr(el, "data-hx-get") == "/page/3"
        @test getattr(el, "data-hx-replace-url") == "/page/3"
        @test getattr(el, "data-hx-target") == "#content"
        @test occursin("transition:true", getattr(el, "data-hx-swap"))
    end

    @testset "rendering: sorted attributes in output" begin
        el = HTMLElement(:div)
        hxget!(el, "/a")
        hxtarget!(el, "#b")
        hxswap!(el, "innerHTML")
        el["id"] = "z"

        html = sprint(print, el)
        # Attributes are sorted alphabetically
        pos_get = Base.findfirst("data-hx-get", html)
        pos_swap = Base.findfirst("data-hx-swap", html)
        pos_target = Base.findfirst("data-hx-target", html)
        pos_id = Base.findfirst("id=", html)

        @test !isnothing(pos_get)
        @test !isnothing(pos_swap)
        @test !isnothing(pos_target)
        @test !isnothing(pos_id)
        # data-hx-get < data-hx-swap < data-hx-target < id
        @test first(pos_get) < first(pos_swap)
        @test first(pos_swap) < first(pos_target)
        @test first(pos_target) < first(pos_id)
    end
end
