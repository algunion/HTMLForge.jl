using Test
using HTMLForge
import HTMLForge: ensurehxprefix, load_trigger, revealed_trigger,
                  intersect_trigger, poll_trigger

@testset "htmx" begin
    @testset "ensurehxprefix" begin
        @test ensurehxprefix("get") == "data-hx-get"
        @test ensurehxprefix(:get) == "data-hx-get"
        @test ensurehxprefix("hx-get") == "data-hx-get"
        @test ensurehxprefix("data-hx-get") == "data-hx-get"
        @test ensurehxprefix("trigger") == "data-hx-trigger"
        @test ensurehxprefix(:trigger) == "data-hx-trigger"
        @test ensurehxprefix("hx-trigger") == "data-hx-trigger"
    end

    @testset "hxattr!" begin
        el = HTMLElement(:div)
        result = hxattr!(el, "custom", "value")
        @test result === el
        @test getattr(el, "data-hx-custom") == "value"
    end

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

    @testset "hxget!" begin
        el = HTMLElement(:div)
        result = hxget!(el, "/api/items")
        @test result === el
        @test getattr(el, "data-hx-get") == "/api/items"
    end

    @testset "hxpost!" begin
        el = HTMLElement(:form)
        result = hxpost!(el, "/api/submit")
        @test result === el
        @test getattr(el, "data-hx-post") == "/api/submit"
    end

    @testset "hxput!" begin
        el = HTMLElement(:div)
        result = hxput!(el, "/api/update")
        @test result === el
        @test getattr(el, "data-hx-put") == "/api/update"
    end

    @testset "hxpatch!" begin
        el = HTMLElement(:div)
        result = hxpatch!(el, "/api/patch")
        @test result === el
        @test getattr(el, "data-hx-patch") == "/api/patch"
    end

    @testset "hxdelete!" begin
        el = HTMLElement(:div)
        result = hxdelete!(el, "/api/remove")
        @test result === el
        @test getattr(el, "data-hx-delete") == "/api/remove"
    end

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

    @testset "load_trigger" begin
        el = HTMLElement(:div)
        result = load_trigger(el)
        @test result === el
        @test getattr(el, "data-hx-trigger") == "load"

        el2 = HTMLElement(:div)
        load_trigger(el2; delay = "1s")
        @test getattr(el2, "data-hx-trigger") == "load delay:1s"
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

    @testset "poll_trigger" begin
        el = HTMLElement(:div)
        result = poll_trigger(el, "2s")
        @test result === el
        @test getattr(el, "data-hx-trigger") == "every 2s"

        el2 = HTMLElement(:div)
        poll_trigger(el2, "500ms")
        @test getattr(el2, "data-hx-trigger") == "every 500ms"
    end

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

    @testset "hxswap! basic" begin
        for style in ["innerHTML", "outerHTML", "afterbegin", "beforebegin",
            "beforeend", "afterend", "delete", "none"]
            el = HTMLElement(:div)
            result = hxswap!(el, style)
            @test result === el
            @test getattr(el, "data-hx-swap") == style
        end
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

    @testset "hxswapoob!" begin
        el = HTMLElement(:div)
        result = hxswapoob!(el)
        @test result === el
        @test getattr(el, "data-hx-swap-oob") == "true"

        el2 = HTMLElement(:div)
        hxswapoob!(el2, "innerHTML:#target")
        @test getattr(el2, "data-hx-swap-oob") == "innerHTML:#target"
    end

    @testset "hxselect!" begin
        el = HTMLElement(:div)
        result = hxselect!(el, "#content")
        @test result === el
        @test getattr(el, "data-hx-select") == "#content"
    end

    @testset "hxselectoob!" begin
        el = HTMLElement(:div)
        result = hxselectoob!(el, "#info-details,#other-elt")
        @test result === el
        @test getattr(el, "data-hx-select-oob") == "#info-details,#other-elt"
    end

    @testset "hxvals!" begin
        el = HTMLElement(:div)
        result = hxvals!(el, "{\"myVal\": \"test\"}")
        @test result === el
        @test getattr(el, "data-hx-vals") == "{\"myVal\": \"test\"}"
    end

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

    @testset "hxreplaceurl!" begin
        el = HTMLElement(:a)
        result = hxreplaceurl!(el)
        @test result === el
        @test getattr(el, "data-hx-replace-url") == "true"

        el2 = HTMLElement(:a)
        hxreplaceurl!(el2, "/new-url")
        @test getattr(el2, "data-hx-replace-url") == "/new-url"
    end

    @testset "hxconfirm!" begin
        el = HTMLElement(:button)
        result = hxconfirm!(el, "Are you sure?")
        @test result === el
        @test getattr(el, "data-hx-confirm") == "Are you sure?"
    end

    @testset "hxprompt!" begin
        el = HTMLElement(:button)
        result = hxprompt!(el, "Enter a value")
        @test result === el
        @test getattr(el, "data-hx-prompt") == "Enter a value"
    end

    @testset "hxindicator!" begin
        el = HTMLElement(:button)
        result = hxindicator!(el, "#spinner")
        @test result === el
        @test getattr(el, "data-hx-indicator") == "#spinner"
    end

    @testset "hxboost!" begin
        el = HTMLElement(:div)
        result = hxboost!(el)
        @test result === el
        @test getattr(el, "data-hx-boost") == "true"

        el2 = HTMLElement(:div)
        hxboost!(el2, "false")
        @test getattr(el2, "data-hx-boost") == "false"
    end

    @testset "hxinclude!" begin
        el = HTMLElement(:div)
        result = hxinclude!(el, "[name='email']")
        @test result === el
        @test getattr(el, "data-hx-include") == "[name='email']"
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

    @testset "hxheaders!" begin
        el = HTMLElement(:div)
        result = hxheaders!(el, "{\"X-CSRF-Token\": \"abc123\"}")
        @test result === el
        @test getattr(el, "data-hx-headers") == "{\"X-CSRF-Token\": \"abc123\"}"
    end

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

    @testset "hxencoding!" begin
        el = HTMLElement(:form)
        result = hxencoding!(el)
        @test result === el
        @test getattr(el, "data-hx-encoding") == "multipart/form-data"

        el2 = HTMLElement(:form)
        hxencoding!(el2, "application/x-www-form-urlencoded")
        @test getattr(el2, "data-hx-encoding") == "application/x-www-form-urlencoded"
    end

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

    @testset "hxdisable!" begin
        el = HTMLElement(:div)
        result = hxdisable!(el)
        @test result === el
        @test hasattr(el, "data-hx-disable")
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

    @testset "hxdisinherit!" begin
        el = HTMLElement(:div)
        result = hxdisinherit!(el, "*")
        @test result === el
        @test getattr(el, "data-hx-disinherit") == "*"

        el2 = HTMLElement(:div)
        hxdisinherit!(el2, "hx-target hx-swap")
        @test getattr(el2, "data-hx-disinherit") == "hx-target hx-swap"
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

    @testset "hxhistory!" begin
        el = HTMLElement(:div)
        result = hxhistory!(el)
        @test result === el
        @test getattr(el, "data-hx-history") == "false"

        el2 = HTMLElement(:div)
        hxhistory!(el2, "true")
        @test getattr(el2, "data-hx-history") == "true"
    end

    @testset "hxhistoryelt!" begin
        el = HTMLElement(:div)
        result = hxhistoryelt!(el)
        @test result === el
        @test hasattr(el, "data-hx-history-elt")
    end

    @testset "hxpreserve!" begin
        el = HTMLElement(:div)
        result = hxpreserve!(el)
        @test result === el
        @test hasattr(el, "data-hx-preserve")
    end

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

    @testset "hxvalidate!" begin
        el = HTMLElement(:div)
        result = hxvalidate!(el)
        @test result === el
        @test getattr(el, "data-hx-validate") == "true"
    end

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
end
