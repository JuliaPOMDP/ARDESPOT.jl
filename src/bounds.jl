init_bounds(bounds, pomdp, sol) = bounds
bounds(f::Function, pomdp::POMDP, b::ScenarioBelief) = f(pomdp, b)
bounds(t::Tuple, pomdp::POMDP, b::ScenarioBelief) = (lbound(t[1], pomdp, b), ubound(t[2], pomdp, b))

function bounds_sanity_check(pomdp::POMDP, sb::ScenarioBelief, L_0, U_0)
    if L_0 > U_0
        warn("L_0 ($L_0) > U_0 ($U_0)   |ϕ| = $(length(sb.scenarios))")
    end
    if all(isterminal(pomdp, s) for s in particles(sb))
        if L_0 != 0.0 || U_0 != 0.0
            error(@sprintf("If all states are terminal, lower and upper bounds should be zero (L_0=%8.2g, U_0=%8.2g).", L_0, U_0))
        end
    end
end


# Upper and lower do not depend on each other (most cases)

struct IndependentBounds{L, U}
    lower::L
    upper::U
end

bounds(bounds::IndependentBounds, pomdp::POMDP, b::ScenarioBelief) = (lbound(bounds.lower, pomdp, b), ubound(bounds.upper, pomdp, b))
function init_bounds(bounds::IndependentBounds, pomdp::POMDP, sol::DESPOTSolver) 
    return IndependentBounds(init_bound(bounds.lower, pomdp, sol),
                             init_bound(bounds.upper, pomdp, sol))
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

ubound(ub::FullyObservableValueUB, pomdp::POMDP, b::ScenarioBelief) = mean(value(p, s) for s in particles(b)) # assumes that all are weighted equally

function init_bound(ub::FullyObservableValueUB{S}, pomdp::POMDP, sol::DESPOTSolver) where S <: Solver
    return FullyObservableValueUB(solve(ub.p, pomdp))
end




# Default Policy Lower Bound

struct DefaultPolicyLB{P<:Union{Solver, Policy}}
    policy::P
    max_depth::Nullable{Int}
end

function DefaultPolicyLB(policy_or_solver::T; max_depth=nothing) where T <: Union{Solver, Policy}
    return DefaultPolicyLB(policy_or_solver, Nullable{Int}(max_depth))
end

function lbound(lb::DefaultPolicyLB, pomdp::POMDP, b::ScenarioBelief)
    rsum = branching_sim(pomdp, lb.policy, b, get(lb.max_depth)-b.depth)
    return rsum/length(b.scenarios)
end

function init_bound(lb::DefaultPolicyLB{S}, pomdp::POMDP, sol::DESPOTSolver) where S <: Solver
    policy = solve(lb.policy, pomdp)
    return init_bound(DefaultPolicyLB(policy, lb.max_depth), pomdp, sol)
end

function init_bound(lb::DefaultPolicyLB{P}, pomdp::POMDP, sol::DESPOTSolver) where P <: Policy
    max_depth = get(lb.max_depth, sol.D)
    return DefaultPolicyLB(lb.policy, Nullable(max_depth))
end
