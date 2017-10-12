__precompile__()
module ARDESPOT

using Parameters
using CPUTime
using ParticleFilters
using POMDPToolbox
using D3Trees

importall POMDPs

using BasicPOMCP # for ExceptionRethrow and NoDecision
import BasicPOMCP.default_action

export
    DESPOTSolver,
    DESPOTPlanner,

    DESPOTRandomSource,
    MersenneSource,
    FastMersenneSource,
    SimpleMersenneSource,
    MemorizingSource,
    MemorizingRNG,

    ScenarioBelief,
    previous_obs,

    default_action,
    NoGap,

    IndependentBounds,
    FullyObservableValueUB,
    DefaultPolicyLB,
    bounds,
    init_bounds


include("random.jl")
include("random_2.jl")


@with_kw mutable struct DESPOTSolver <: Solver
    epsilon_0::Float64                      = 0.0
    xi::Float64                             = 0.95
    K::Int                                  = 500
    D::Int                                  = 90
    lambda::Float64                         = 0.01
    T_max::Float64                          = 1.0
    max_trials::Int                         = typemax(Int)
    bounds::Any                             = IndependentBounds(-1e6, 1e6)
    default_action::Any                     = ExceptionRethrow()
    rng::AbstractRNG                        = Base.GLOBAL_RNG
    random_source::DESPOTRandomSource       = FastMersenneSource(K, 50)
end

include("scenario_belief.jl")
include("default_policy_sim.jl")
include("bounds.jl")

struct DESPOTPlanner{P<:POMDP, B, RS<:DESPOTRandomSource, RNG<:AbstractRNG} <: Policy
    sol::DESPOTSolver
    pomdp::P
    bounds::B
    rs::RS
    rng::RNG
end

function DESPOTPlanner(sol::DESPOTSolver, pomdp::POMDP)
    bounds = init_bounds(sol.bounds, pomdp, sol)
    rng = deepcopy(sol.rng)
    rs = deepcopy(sol.random_source)
    srand(rs, rand(rng, UInt32))
    return DESPOTPlanner(deepcopy(sol), pomdp, bounds, rs, rng)
end

include("tree.jl")
include("planner.jl")
include("pomdps_glue.jl")

# include("tree_printing.jl")
include("visualization.jl")
include("exceptions.jl")

end # module
