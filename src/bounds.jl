# Upper and lower do not depend on each other (most cases)

struct IndependentBounds{L, U} <: DESPOTBounds
    lower::L
    upper::U
end

bounds(bounds::IndependentBounds, pomdp, b::ScenarioBelief) = (lbound(bounds.lower, pomdp, b), ubound(bounds.upper, pomdp, b))
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

ubound(ub::FullyObservableValueUB, pomdp::POMDP, b::ScenarioBelief) = mean(value(p, s) for s in iterator(b)) # assumes that all are weighted equally

function init_bound(ub::FullyObservableValueUB{S}, pomdp::POMDP, sol::DESPOTSolver) where S <: Solver
    return FullyObservableValueUB(solve(ub.p, pomdp))
end




# Default Policy Lower Bound

struct DefaultPolicyLB{P<:Union{Solver, Policy}, U<:Updater}
    policy::P
    updater::Nullable{U}
    max_depth::Nullable{Int}
end

function DefaultPolicyLB(policy_or_solver::T, max_depth=nothing) where T <: Union{Solver, Policy}
    return DefaultPolicyLB(policy_or_solver, Nullable(), Nullable{Int}(max_depth))
end

function lbound(lb::DefaultPolicyLB, pomdp::POMDP, b::ScenarioBelief)
    rsum = 0.0
    for (i, s) in b.scenarios
        sim = ScenarioSimulator(b.random_source, i, b.depth, get(lb.max_depth)-b.depth)
        rsum += simulate(sim, pomdp, lb.policy, get(lb.updater), b, s)
    end
    return rsum/length(b.scenarios)
end

function init_bound(lb::DefaultPolicyLB{S}, pomdp::POMDP, sol::DESPOTSolver) where S <: Solver
    policy = solve(lb.policy, pomdp)
    return init_bound(DefaultPolicyLB(policy, Nullable(lb.updater), Nullable(lb.max_depth)), pomdp, sol)
end

function init_bound(lb::DefaultPolicyLB{P}, pomdp::POMDP, sol::DESPOTSolver) where P <: Policy
    up = get(lb.updater, updater(lb.policy))
    max_depth = get(lb.max_depth, sol.D)
    return DefaultPolicyLB(lb.policy, Nullable(up), Nullable(max_depth))
end
