using Distributions
# A one-dimensional light-dark problem, originally used to test MCVI
# A very simple POMDP with continuous state and observation spaces.
# maintained by @zsunberg

"""
    LightDark1D_DO

A one-dimensional light dark problem. The goal is to be near 0. Observations are noisy measurements of the position.

Model
-----

   -3-2-1 0 1 2 3
...| | | | | | | | ...
          G   S

Here G is the goal. S is the starting location
"""
mutable struct LightDark1D_DO{F<:Function} <: POMDPs.POMDP{LightDark1DState,Int,Float64}
    discount_factor::Float64
    correct_r::Float64
    incorrect_r::Float64
    step_size::Float64
    movement_cost::Float64
    sigma::F
    grid::Tuple{Float64, Float64}
    grid_step::Float64
    grid_len::Int
end

default_sigma(x::Float64) = abs(x - 5)/sqrt(2) + 1e-2

function LightDark1D_DO(;grid = collect(-10:20/40:10))
    return LightDark1D_DO(0.9, 10.0, -10.0, 1.0, 0.0, default_sigma,(first(grid),last(grid)),round(grid[2]-grid[1],digits=4),length(grid))
end

POMDPs.discount(p::LightDark1D_DO) = p.discount_factor

POMDPs.isterminal(::LightDark1D_DO, act::Int64) = act == 0

POMDPs.isterminal(::LightDark1D_DO, s::LightDark1DState) = s.status < 0


POMDPs.actions(::LightDark1D_DO) = -1:1

POMDPs.initialstate(pomdp::LightDark1D_DO) = POMDPModels.LDNormalStateDist(2, 3)
POMDPs.initialobs(m::LightDark1D_DO, s) = observation(m, s)

struct DiscreteNormal
    dist::Normal{Float64}
    g_first::Float64
    g_end::Float64
    step::Float64
end

function DiscreteNormal(p::LightDark1D_DO,dist::Normal{Float64})
    return DiscreteNormal(dist,p.grid[1],p.grid[2],p.grid_step)
end

function Base.rand(rng::AbstractRNG,dist::DiscreteNormal)
    val = rand(rng,dist.dist)
    # @show val
    # @show ceil((val-dist.g_first)/dist.step)*dist.step+dist.g_first
    return ceil((val-dist.g_first)/dist.step)*dist.step+dist.g_first
end

function Distributions.pdf(dist::DiscreteNormal,x::Float64)
    @assert ceil(round((x-dist.g_first)/dist.step),digits=8)%1.0 == 0.0
    discx = x
    val = 0.0
    if x <= dist.g_first
        val = cdf(dist.dist,discx)
    elseif x >= dist.g_end
        val = 1.0-cdf(dist.dist,discx-dist.step)
    else
        val = cdf(dist.dist,discx)-cdf(dist.dist,discx-dist.step)
    end
    return val
end

function POMDPs.observation(p::LightDark1D_DO, sp::LightDark1DState)
    return DiscreteNormal(p,Normal(sp.y, p.sigma(sp.y)))
end

# function POMDPs.observation(p::LightDark1D_DO, sp::LightDark1DState)
#     dist = Normal(sp.y, p.sigma(sp.y))
#     o_vals = zeros(p.grid_len)
#     old_cdf = 0.0
#     grid = collect(p.grid[1]:p.grid_step:p.grid[2])
#     for (i,g) in enumerate(grid)
#         if i == 1
#             old_cdf = cdf(dist,g)
#             o_vals[i] = old_cdf
#         elseif i == p.grid_len
#             o_vals[end] = 1.0-old_cdf
#         else
#             new_cdf = cdf(dist,g)
#             o_vals[i] = new_cdf-old_cdf
#             old_cdf = new_cdf
#         end
#     end
#     # @assert all(o_vals .>= 0)
#     # @assert abs(sum(o_vals)-1.0) < 0.0001
#     return SparseCat(grid,o_vals)
# end

function POMDPs.transition(p::LightDark1D_DO, s::LightDark1DState, a::Int)
    if a == 0
        return Deterministic(LightDark1DState(-1, s.y+a*p.step_size))
    else
        return Deterministic(LightDark1DState(s.status, s.y+a*p.step_size))
    end
end

function POMDPs.reward(p::LightDark1D_DO, s::LightDark1DState, a::Int)
    if s.status < 0
        return 0.0
    elseif a == 0
        if abs(s.y) < 1
            return p.correct_r
        else
            return p.incorrect_r
        end
    else
        return -p.movement_cost*a
    end
end


convert_s(::Type{A}, s::LightDark1DState, p::LightDark1D_DO) where A<:AbstractArray = eltype(A)[s.status, s.y]
convert_s(::Type{LightDark1DState}, s::A, p::LightDark1D_DO) where A<:AbstractArray = LightDark1DState(Int64(s[1]), s[2])