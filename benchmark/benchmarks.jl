using Pkg
Pkg.activate(".")
using ARDESPOT

Pkg.activate("benchmark")
using BenchmarkTools

using POMDPs
using POMDPModels
using Random
using POMDPTools
using ParticleFilters


##Baby Tests
pomdp = BabyPOMDP()
pomdp.discount = 1.0
bds = IndependentBounds(DefaultPolicyLB(FeedWhenCrying()), 0.0)
solver = DESPOTSolver(bounds=bds,T_max=Inf,max_trials=1000,rng=MersenneTwister(5))
planner = solve(solver, pomdp)
hr = HistoryRecorder(max_steps=2)
println("BabyPOMDP ===================================")
display(@benchmark simulate(hr, pomdp, planner))
println("")

##Tiger Tests
pomdp = TigerPOMDP()

solver = DESPOTSolver(bounds=(-20.0, 0.0),T_max=Inf,max_trials=1000,rng=MersenneTwister(5))
planner = solve(solver, pomdp)

hr = HistoryRecorder(max_steps=3)
println("Tiger  ===================================")
display(@benchmark simulate(hr, pomdp, planner))
println("")

##LightDark POMDP
include("LD_disc_o.jl")
pomdp = LightDark1D_DO(;grid = collect(-10:20/40:10))

lb_pol = FunctionPolicy(b->-1)
bds = IndependentBounds(DefaultPolicyLB(lb_pol), pomdp.correct_r,check_terminal=true)
solver = DESPOTSolver(bounds=bds,T_max=Inf,max_trials=1000,rng=MersenneTwister(5))
planner = solve(solver, pomdp)
hr = HistoryRecorder(max_steps=2)
println("LightDark D.O. - 40 Obs  ===================================")
display(@benchmark simulate(hr, pomdp, planner))
println("")

##LD 2
pomdp = LightDark1D_DO(;grid = collect(-10:20/100:10))

lb_pol = FunctionPolicy(b->-1)
bds = IndependentBounds(DefaultPolicyLB(lb_pol), pomdp.correct_r,check_terminal=true)
solver = DESPOTSolver(bounds=bds,T_max=Inf,max_trials=1000,rng=MersenneTwister(5))
planner = solve(solver, pomdp)
hr = HistoryRecorder(max_steps=2)
println("LightDark D.O. - 100 Obs  ===================================")
display(@benchmark simulate(hr, pomdp, planner))
println("")

#Add RockSample???
"done"