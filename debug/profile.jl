using Revise

using POMDPs
using ARDESPOT
using ProfileView
using POMDPModels
using BenchmarkTools

pomdp = BabyPOMDP()
bounds = IndependentBounds(DefaultPolicyLB(FeedWhenCrying()), 0.0)
# bounds = IndependentBounds(reward(pomdp, false, true)/(1-discount(pomdp)), 0.0)
solver = DESPOTSolver(epsilon_0=0.0,
                      K=50,
                      D=50,
                      bounds=bounds,
                      T_max=Inf,
                      max_trials=100,
                      rng=MersenneTwister(4),
                      random_source=FastMersenneSource(500, 10, MersenneTwister(4))
                     )
p = solve(solver, pomdp)
b0 = initial_state_distribution(pomdp)
println("starting first")
@time ARDESPOT.build_despot(p, b0)
@time ARDESPOT.build_despot(p, b0)

Profile.clear()
D = @profile for i in 1:100
    ARDESPOT.build_despot(p, b0)
end
ProfileView.view()
