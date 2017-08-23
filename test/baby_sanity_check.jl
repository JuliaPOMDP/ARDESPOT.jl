using POMDPs
using ARDESPOT
using POMDPToolbox
using POMDPModels
using ProgressMeter

T = 50
N = 50

pomdp = BabyPOMDP()

bounds = IndependentBounds(reward(pomdp, true, false)/(1-discount(pomdp)), 0.0)

solver = DESPOTSolver(epsilon_0=0.1,
                      bounds=bounds,
                      T_max=0.05,
                      rng=MersenneTwister(4)
                     )


rsum = 0.0
fwc_rsum = 0.0
@showprogress for i in 1:N
    planner = solve(solver, pomdp)
    sim = RolloutSimulator(max_steps=T, rng=MersenneTwister(i))
    fwc_sim = deepcopy(sim)
    rsum += simulate(sim, pomdp, planner)
    fwc_rsum += simulate(fwc_sim, pomdp, FeedWhenCrying())
end

@show rsum/N
@show fwc_rsum/N
