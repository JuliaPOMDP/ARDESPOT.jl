include("memorizing_rng.jl")

import Base.Random.MTCacheLength

mutable struct MemorizingSource{RNG<:AbstractRNG} <: DESPOTRandomSource
    rng::RNG
    memory::Vector{Float64}
    rngs::Matrix{MemorizingRNG{MemorizingSource{RNG}}}
    furthest::Int
end

function MemorizingSource(K::Int, depth::Int, rng::AbstractRNG)
    RNG = typeof(rng)
    memory = Float64[]
    rngs = Matrix{MemorizingRNG{MemorizingSource{RNG}}}(depth, K)
    return MemorizingSource{RNG}(rng, memory, rng, 0)
end

function get_rng(s::MemorizingSource, scenario::Int, depth::Int)
    if isassigned(s.rngs, depth+1, scenario)
        rng = s.rngs
    else
    range = s.ranges[depth+1, scenario]
    if range == 0:0
        range = s.furthest+1:s.furthest
    end
    return MemorizingRNG(s.memory, range, 0, s)
end

function srand(s::MemorizingSource, seed)
    srand(s.rng, seed)
    fill!(s.ranges, 0:0)
    resize!(s.memory, 0)
    return s
end

function gen_rand!(r::MemorizingRNG{MemorizingSource{MersenneTwister}}, n::Integer)
    s = r.source
    if last(r.range) == s.furthest
        orig = length(s.memory)
        if orig < s.furthest + n
            resize!(s.memory, orig+MTCacheLength)
            Base.Random.gen_rand(s.rng) # could be faster to use dsfmt_fill_array_close1_open2
            s.memory[orig+1:end] = s.rng.vals
            Base.Random.mt_setempty!(s.rng)
        end
        s.furthest += n
        r.range = first(r.range):last(r.range+n)
    else
        error("tried to gen_rand on an rng that is not the head")
    end
    return nothing
end
