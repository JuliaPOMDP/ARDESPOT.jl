abstract type DESPOTRandomSource end

check_consistency(rs::DESPOTRandomSource) = nothing

include("memorizing_rng.jl")

import Random.MT_CACHE_F

mutable struct MemorizingSource{RNG<:AbstractRNG} <: DESPOTRandomSource
    rng::RNG
    memory::Vector{Float64}
    rngs::Matrix{MemorizingRNG{MemorizingSource{RNG}}}
    furthest::Int
    min_reserve::Int
    grow_reserve::Bool
    move_count::Int
    move_warning::Bool
end

function MemorizingSource(K::Int, depth::Int, rng::AbstractRNG; min_reserve=0, grow_reserve=true, move_warning=true)
    RNG = typeof(rng)
    memory = Float64[]
    rngs = Matrix{MemorizingRNG{MemorizingSource{RNG}}}(undef, depth+1, K)
    src = MemorizingSource{RNG}(rng, memory, rngs, 0, min_reserve, grow_reserve, 0, move_warning)
    for i in 1:K
        for j in 1:depth+1
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

function Random.seed!(s::MemorizingSource, seed)
    Random.seed!(s.rng, seed)
    resize!(s.memory, 0)
    for i in 1:size(s.rngs, 2)
        for j in 1:size(s.rngs, 1)
            s.rngs[j, i] = MemorizingRNG(s.memory, 1, 0, 0, s)
        end
    end
    s.furthest = 0
    s.move_count = 0
    return s
end

function gen_rand!(r::MemorizingRNG{MemorizingSource{MersenneTwister}}, n::Integer)
    s = r.source

    # make sure that we're on the very end of the source's memory
    if r.finish != s.furthest # we need to move the memory to the end
        len = r.finish - r.start + 1
        if length(s.memory) < s.furthest + len
            resize!(s.memory, s.furthest + len)
        end
        s.memory[s.furthest+1:s.furthest+len] = s.memory[r.start:r.finish]
        r.idx = r.idx - r.start + s.furthest + 1
        r.start = s.furthest + 1
        r.finish = s.furthest + len
        s.furthest += len
        s.move_count += 1
        if s.grow_reserve
            s.min_reserve = max(s.min_reserve, len + n)
        end
    end

    @assert r.finish == s.furthest
    orig = length(s.memory)
    if orig < s.furthest + n
        @assert n <= MT_CACHE_F
        resize!(s.memory, orig+MT_CACHE_F)
        Random.gen_rand(s.rng) # could be faster to use dsfmt_fill_array_close1_open2
        s.memory[orig+1:end] = s.rng.vals
        Random.mt_setempty!(s.rng)
    end
    s.furthest += n
    r.finish += n
    return nothing
end

Random.rng_native_52(s::MemorizingSource) = Random.rng_native_52(s.rng)

function check_consistency(s::MemorizingSource)
    if s.move_count > 0.01*length(s.rngs) && s.move_warning
        @warn("""
             DESPOT's MemorizingSource random number generator had to move the memory locations of the rngs $(s.move_count) times. If this number was large, it may be affecting performance (profiling is the best way to tell).

             To suppress this warning, use MemorizingSource(..., move_warning=false).

             To reduce the number of moves, try using MemorizingSource(..., min_reserve=n) and increase n until the number of moves is low (the final min_reserve was $(s.min_reserve)).
             """)
    end
end
