using ARDESPOT
using Base.Test

using POMDPs
using POMDPModels
using POMDPToolbox

pomdp = BabyPOMDP()

bounds = IndependentBounds(reward(pomdp, true, false)/(1-discount(pomdp)), 0.0)
solver = DESPOTSolver(bounds=bounds)
planner = solve(solver, pomdp)
hr = HistoryRecorder(max_steps=10)
hist = simulate(hr, pomdp, planner)

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
@show D.children
@inferred ARDESPOT.explore!(D, 1, p)
@inferred ARDESPOT.expand!(D, length(D.children), p)
@inferred ARDESPOT.prune!(D, 1, p)
@inferred ARDESPOT.find_blocker(D, length(D.children), p)
@inferred ARDESPOT.make_default!(D, length(D.children))
@inferred ARDESPOT.backup!(D, 1, p)
@inferred ARDESPOT.next_best(D, 1, p)
@inferred ARDESPOT.excess_uncertainty(D, 1, p)
