module ARDESPOT

using POMDPs
using BeliefUpdaters
using Parameters
using CPUTime
using ParticleFilters
using D3Trees
using Random
using Printf
using POMDPModelTools

using BasicPOMCP # for ExceptionRethrow and NoDecision
import BasicPOMCP.default_action

import Random.rand

export
    DESPOTSolver,
    DESPOTPlanner,

    DESPOTRandomSource,
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
    init_bounds,
    lbound,
    ubound,
    init_bound,

    ReportWhenUsed


# include("random.jl")
include("random_2.jl")

"""
    DESPOTSolver

    An implementation of the ARDESPOT solver trying to closely match the pseudeo
    code of:

    http://bigbird.comp.nus.edu.sg/m2ap/wordpress/wp-content/uploads/2017/08/jair14.pdf


    Fields:

    epsilon_0::Float64
        The target gap between the upper and the lower bound at the root of the partial DESPOT.

    xi::Float64
        The rate of target gap reduction.

    K::Int
        The number of sampled scenarios.

    D::Int
        The maximum depth of the DESPOT.

    lambda::Float64
        Reguluarization constant.

    T_max::Float64
        The maximum online planning time per step.

    max_trials::Int
        The maximum number of trials of the planner.

    bounds::Any
        A representation for the upper and lower bound on the RWDU (e.g. IndependentBounds).

    default_action::Any
        A default action to be returned if the algorithm fails to provide an action.

    rng::AbstractRNG
        A random number generator for the internal sampling processes.

    random_source::DESPOTRandomSource
        A source for random numbers in scenario rollout

    bounds_warnings::Bool
        If true, sanity checks on the provided bounds are performed.

    tree_in_info::Bool
        If true, a reprenstation of the constructed DESPOT is returned by POMDPModelTools.action_info.
"""
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
    rng::AbstractRNG                        = Random.GLOBAL_RNG
    random_source::DESPOTRandomSource       = MemorizingSource(K, D, rng)
    bounds_warnings::Bool                   = true
    tree_in_info::Bool                      = false
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
    Random.seed!(rs, rand(rng, UInt32))
    return DESPOTPlanner(deepcopy(sol), pomdp, bounds, rs, rng)
end

include("tree.jl")
include("planner.jl")
include("pomdps_glue.jl")

include("visualization.jl")
include("exceptions.jl")

end # module
