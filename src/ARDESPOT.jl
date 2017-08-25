module ARDESPOT

using Parameters
using CPUTime
using ParticleFilters
using POMDPToolbox

importall POMDPs

export
    DESPOTSolver,
    DESPOTPlanner,

    DESPOTRandomSource,
    MersenneSource,
    FastMersenneSource,
    SimpleMersenneSource,
    ScenarioBelief,

    DESPOTBounds,
    IndependentBounds,
    FullyObservableValueUB,
    DefaultPolicyLB,

    TreeView


include("random.jl")

abstract type DESPOTBounds end

@with_kw mutable struct DESPOTSolver
    epsilon_0::Float64                      = 0.0
    xi::Float64                             = 0.95
    K::Int                                  = 500
    D::Int                                  = 90
    lambda::Float64                         = 0.01
    T_max::Float64                          = 1.0
    max_trials::Int                         = typemax(Int)
    bounds::DESPOTBounds                    = IndependentBounds(-1e6, 1e6)
    rng::AbstractRNG                        = Base.GLOBAL_RNG
    random_source::DESPOTRandomSource       = FastMersenneSource(K, rng)
end

include("scenario_belief.jl")
include("default_policy_sim.jl")
include("bounds.jl")

struct DESPOTPlanner{P<:POMDP, B<:DESPOTBounds, RS<:DESPOTRandomSource, RNG<:AbstractRNG} <: Policy
    sol::DESPOTSolver
    pomdp::P
    bounds::B
    rs::RS
    rng::RNG
end

function DESPOTPlanner(sol::DESPOTSolver, pomdp::POMDP)
    bounds = init_bounds(sol.bounds, pomdp, sol)
    return DESPOTPlanner(deepcopy(sol), pomdp, bounds, deepcopy(sol.random_source), deepcopy(sol.rng))
end

include("tree.jl")
include("planner.jl")
include("pomdps_glue.jl")

include("tree_printing.jl")

end # module
