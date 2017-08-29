using ARDESPOT
using Base.Test

using POMDPs
using POMDPModels
using POMDPToolbox

pomdp = BabyPOMDP()

# FastMersenneSource
rs = FastMersenneSource(10, 50)
srand(rs, 7)
mt = ARDESPOT.get_rng(rs, 3, 8)
r1 = rand(mt)
mt = ARDESPOT.get_rng(rs, 3, 8)
r2 = rand(mt)
@test r1 == r2

K = 10
rng = MersenneTwister(14)
rs = FastMersenneSource(K, 50)
srand(rs, 10)
b_0 = initial_state_distribution(pomdp)
scenarios = [i=>rand(rng, b_0) for i in 1:K]
b = ScenarioBelief(scenarios, rs, 0, Nullable(false))
pol = FeedWhenCrying()
up = updater(pol)
sim = ARDESPOT.ScenarioSimulator(rs, 7, 0, 100)
r1 = simulate(sim, pomdp, pol, up, b, false)
r2 = simulate(sim, pomdp, pol, up, b, false)
@test r1 == r2

# constant bounds
bounds = IndependentBounds(reward(pomdp, true, false)/(1-discount(pomdp)), 0.0)
solver = DESPOTSolver(bounds=bounds)
planner = solve(solver, pomdp)
hr = HistoryRecorder(max_steps=2)
@time hist = simulate(hr, pomdp, planner)

# policy lower bound
bounds = IndependentBounds(DefaultPolicyLB(FeedWhenCrying()), 0.0)
solver = DESPOTSolver(bounds=bounds)
planner = solve(solver, pomdp)
hr = HistoryRecorder(max_steps=2)
@time hist = simulate(hr, pomdp, planner)

# RewindingMersenneSource
bounds = IndependentBounds(DefaultPolicyLB(FeedWhenCrying()), 0.0)
solver = DESPOTSolver(bounds=bounds,
                      random_source=FastMersenneSource(500, 50))
planner = solve(solver, pomdp)
hr = HistoryRecorder(max_steps=2)
@time hist = simulate(hr, pomdp, planner)


# Type stability 
pomdp = BabyPOMDP()
bounds = IndependentBounds(reward(pomdp, true, false)/(1-discount(pomdp)), 0.0)
solver = DESPOTSolver(epsilon_0=0.1,
                      bounds=bounds,
                      rng=MersenneTwister(4)
                     )
p = solve(solver, pomdp)

b0 = initial_state_distribution(pomdp)
D = @inferred ARDESPOT.build_despot(p, b0)
@inferred ARDESPOT.explore!(D, 1, p)
@inferred ARDESPOT.expand!(D, length(D.children), p)
@inferred ARDESPOT.prune!(D, 1, p)
@inferred ARDESPOT.find_blocker(D, length(D.children), p)
@inferred ARDESPOT.make_default!(D, length(D.children))
@inferred ARDESPOT.backup!(D, 1, p)
@inferred ARDESPOT.next_best(D, 1, p)
@inferred ARDESPOT.excess_uncertainty(D, 1, p)
@inferred action(p, b0)
