module ARDESPOT

using Parameters
using CPUTime

importall POMDPs

@with_kw mutable struct DESPOTSolver
    epsilon_0::Float64  = 0.0
    xi::Float64         = 0.95
    K::Int              = 500
    D::Int              = 90
    lambda::Float64     = 0.01
    T_max::Float64      = 1.0
    rng::AbstractRNG    = Base.GLOBAL_RNG
end

struct DESPOTPlanner{P<:POMDP, RNG<:AbstractRNG}
    sol::DESPOTSolver
    pomdp::P
    rng::RNG
end

include("tree.jl")
include("planner.jl")

end # module
