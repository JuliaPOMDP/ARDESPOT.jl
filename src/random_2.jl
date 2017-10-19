include("memorizing_rng.jl")

import Base.Random.MTCacheLength

mutable struct MemorizingSource{RNG<:AbstractRNG} <: DESPOTRandomSource
    rng::RNG
    memory::Vector{Float64}
    rngs::Matrix{MemorizingRNG{MemorizingSource{RNG}}}
    furthest::Int
    min_reserve::Int
end

function MemorizingSource(K::Int, depth::Int, rng::AbstractRNG; min_reserve=0)
    RNG = typeof(rng)
    memory = Float64[]
    rngs = Matrix{MemorizingRNG{MemorizingSource{RNG}}}(depth, K)
    src = MemorizingSource{RNG}(rng, memory, rngs, 0, min_reserve)
    for i in 1:K
        for j in 1:depth
            rngs[j, i] = MemorizingRNG(src.memory, 1, 0, 0, src)
        end
    end
    return src
end

function get_rng(s::MemorizingSource, scenario::Int, depth::Int)
    rng = s.rngs[depth+1, scenario]
    if rng.finish == 0
        rng.start = s.furthest+1
        rng.idx = rng.start - 1
        rng.finish = s.furthest
        reserve(rng, s.min_reserve)
    end
    rng.idx = rng.start - 1
    return rng
end

function srand(s::MemorizingSource, seed)
    srand(s.rng, seed)
    resize!(s.memory, 0)
    for i in size(s.rngs, 2)
        for j in size(s.rngs, 1)
            s.rngs[j, i] = MemorizingRNG(s.memory, 1, 0, 0, s)
        end
    end
    s.furthest = 0
    return s
end

function gen_rand!(r::MemorizingRNG{MemorizingSource{MersenneTwister}}, n::Integer)
    s = r.source
    if r.finish == s.furthest
        orig = length(s.memory)
        if orig < s.furthest + n
            @assert n <= MTCacheLength
            resize!(s.memory, orig+MTCacheLength)
            Base.Random.gen_rand(s.rng) # could be faster to use dsfmt_fill_array_close1_open2
            s.memory[orig+1:end] = s.rng.vals
            Base.Random.mt_setempty!(s.rng)
        end
        s.furthest += n
        r.finish += n
    else
        error("""
              Tried to gen_rand on an rng that is not the head.
              
              r.start = $(r.start)
              r.finish = $(r.finish)
              r.idx = $(r.idx)
              n = $n

              Try using MemorizingSource(..., min_reserve=$(r.finish+n-r.start+1)) (or larger).
              """)
    end
    return nothing
end
