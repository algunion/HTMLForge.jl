using Test
using HTMLForge

testdir = dirname(@__FILE__)

include("basics.jl")
include("comparison.jl")
include("parsing.jl")
include("traversal.jl")
include("manipulation.jl")
include("io.jl")
include("htmx.jl")
