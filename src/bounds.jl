init_bounds(bounds, pomdp, sol) = bounds
init_bounds(t::Tuple, pomdp, sol) = (init_bound(first(t), pomdp, sol), init_bound(last(t), pomdp, sol))
bounds(f::Function, pomdp::POMDP, b::ScenarioBelief) = f(pomdp, b)
bounds(t::Tuple, pomdp::POMDP, b::ScenarioBelief) = (lbound(t[1], pomdp, b), ubound(t[2], pomdp, b))

function bounds_sanity_check(pomdp::POMDP, sb::ScenarioBelief, L_0, U_0)
    if L_0 > U_0
        @warn("L_0 ($L_0) > U_0 ($U_0)   |ϕ| = $(length(sb.scenarios))")
    end
    if all(isterminal(pomdp, s) for s in particles(sb))
        if L_0 != 0.0 || U_0 != 0.0
            error(@sprintf("If all states are terminal, lower and upper bounds should be zero (L_0=%-10.2g, U_0=%-10.2g). (try IndependentBounds(l, u, check_terminal=true))", L_0, U_0))
        end
    end
    if isinf(L_0) || isnan(L_0)
        @warn("L_0 = $L_0. Infinite bounds are not supported.")
    end
    if isinf(U_0) || isnan(U_0)
        @warn("U_0 = $U_0. Infinite bounds are not supported.")
    end
end

"""
    IndependentBounds(l, u, check_terminal=false)

Specify lower and upper bounds that are independent of each other (the most common case).

This differs from specifying bounds as a `Tuple` because of the `check_terminal` option. If `check_terminal` is true, then if all the states in the belief are terminal, the upper and lower bounds will be overridden and set to 0.
"""
struct IndependentBounds{L, U}
    lower::L
    upper::U
    check_terminal::Bool
end

IndependentBounds(l, u; check_terminal=false) = IndependentBounds(l, u, check_terminal)

function bounds(bounds::IndependentBounds, pomdp::POMDP, b::ScenarioBelief)
    if bounds.check_terminal && all(isterminal(pomdp, s) for s in particles(b))
        return (0.0, 0.0)
    end
    return (lbound(bounds.lower, pomdp, b), ubound(bounds.upper, pomdp, b))
end

function init_bounds(bounds::IndependentBounds, pomdp::POMDP, sol::DESPOTSolver) 
    return IndependentBounds(init_bound(bounds.lower, pomdp, sol),
                             init_bound(bounds.upper, pomdp, sol),
                             bounds.check_terminal
                            )
end
init_bound(bound, pomdp, sol) = bound

ubound(n::Number, pomdp, b) = convert(Float64, n)
lbound(n::Number, pomdp, b) = convert(Float64, n)

ubound(f::Function, pomdp, b) = f(pomdp, b)
lbound(f::Function, pomdp, b) = f(pomdp, b)




# Value if Fully Observed Under a Policy
struct FullyObservableValueUB{P<:Union{Solver, Policy}}
    p::P
end

ubound(ub::FullyObservableValueUB, pomdp::POMDP, b::ScenarioBelief) = mean(value(ub.p, s) for s in particles(b)) # assumes that all are weighted equally

function init_bound(ub::FullyObservableValueUB{S}, pomdp::POMDP, sol::DESPOTSolver) where S <: Solver
    return FullyObservableValueUB(solve(ub.p, pomdp))
end




# Default Policy Lower Bound

"""
    DefaultPolicyLB(policy; max_depth=nothing, final_value=(m,x)->0.0)
    DefaultPolicyLB(solver; max_depth=nothing, final_value=(m,x)->0.0)

A lower bound calculated by running a default policy on the scenarios in a belief.

# Keyword Arguments
- `max_depth::Union{Nothing,Int}=nothing`: max depth to run the simulation. The depth of the belief will be automatically subtracted so simulations for the bound will be run for `max_depth-b.depth` steps. If `nothing`, the solver's max depth will be used.
- `final_value=(m,x)->0.0`: a function (or callable object) that specifies an additional value to be added at the end of the simulation when `max_depth` is reached. This function will be called with two arguments, a `POMDP`, and a `ScenarioBelief`. It will not be called when the states in the belief are terminal.
"""
struct DefaultPolicyLB{P<:Union{Solver, Policy}, D<:Union{Nothing,Int}, T}
    policy::P
    max_depth::D
    final_value::T
end

function DefaultPolicyLB(policy_or_solver::T;
                         max_depth=nothing,
                         final_value=(m,x)->0.0) where T <: Union{Solver, Policy}
    return DefaultPolicyLB(policy_or_solver, max_depth, final_value)
end

function lbound(lb::DefaultPolicyLB, pomdp::POMDP, b::ScenarioBelief)
    rsum = branching_sim(pomdp, lb.policy, b, lb.max_depth-b.depth, lb.final_value)
    return rsum/length(b.scenarios)
end

function init_bound(lb::DefaultPolicyLB{S}, pomdp::POMDP, sol::DESPOTSolver) where S <: Solver
    policy = solve(lb.policy, pomdp)
    return init_bound(DefaultPolicyLB(policy, lb.max_depth, lb.final_value), pomdp, sol)
end

function init_bound(lb::DefaultPolicyLB{P}, pomdp::POMDP, sol::DESPOTSolver) where P <: Policy
    max_depth = something(lb.max_depth, sol.D)
    return DefaultPolicyLB(lb.policy, max_depth, lb.final_value)
end
