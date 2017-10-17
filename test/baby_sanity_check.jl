using POMDPs
using ARDESPOT
using POMDPToolbox
using POMDPModels
using ProgressMeter

T = 50
N = 50

pomdp = BabyPOMDP()

bounds = IndependentBounds(DefaultPolicyLB(FeedWhenCrying()), 0.0)
# bounds = IndependentBounds(reward(pomdp, false, true)/(1-discount(pomdp)), 0.0)

solver = DESPOTSolver(epsilon_0=0.1,
                      K=100,
                      D=50,
                      lambda=0.01,
                      bounds=bounds,
                      T_max=Inf,
                      max_trials=500,
                      rng=MersenneTwister(4),
                      # random_source=SimpleMersenneSource(50),
                      random_source=FastMersenneSource(100, 10),
                      # random_source=MersenneSource(50, 10, MersenneTwister(10))
                     )

@show solver.lambda

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
