struct ScenarioBelief{S, RS<:DESPOTRandomSource}
    scenarios::Vector{Pair{Int,S}}
    random_source::RS
    # ao_history::Nullable{AOHistory}() # may put this in later
end

rand(rng::AbstractRNG, b::ScenarioBelief) = b.scenarios[rand(rng, 1:length(b.scenarios))]
iterator(b::ScenarioBelief) = (last(p) for p in b.scenarios)

init_bounds(bounds, pomdp, sol) = bounds

struct IndependentBounds{L, U} <: DESPOTBounds
    lower::L
    upper::U
end

bounds(bounds::IndependentBounds, b::ScenarioBelief) = (lbound(bounds.lower, b), ubound(bounds.upper, b))
function init_bounds(bounds::IndependentBounds, pomdp::POMDP, sol::DESPOTSolver) 
    return IndependentBounds(init_bound(bounds.lower, pomdp, sol),
                             init_bound(bounds.upper, pomdp, sol))
end
init_bound(bound, pompd, sol) = bound

ubound(n::Number, b) = convert(Float64, n)
lbound(n::Number, b) = convert(Float64, n)

# lower: default policy
# upper: fully observable

# upper bound by estimating the fully observable value of the states
struct FullyObservableValueUB{P<:Union{Solver, Policy}}
    p::P
end

ubound(ub::FullyObservableValueUB, b::ScenarioBelief) = mean(value(p, s) for s in iterator(b)) # assumes that all are weighted equally
function init_bound(ub::FullyObservableValueUB{S}, pomdp::POMDP, sol::DESPOTSolver) where S <: Solver
    return FullyObservableValueUB(solve(ub.p, pomdp))
end
