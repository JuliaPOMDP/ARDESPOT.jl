include("memorizing_rng.jl")

import Base.Random.MTCacheLength

mutable struct MemorizingSource{RNG<:AbstractRNG} <: DESPOTRandomSource
    rng::RNG
    memory::Vector{Float64}
    ranges::Matrix{UnitRange{Int64}}
    furthest::Int
    head::MemorizingRNG{MemorizingSource{RNG}, SubArray{Float64,1,Array{Float64,1},Tuple{UnitRange{Int64}},true}}

    MemorizingSource{RNG}(rng, memory, ranges, furthest) where RNG = new(rng, memory, ranges, furthest)
end

function MemorizingSource(K::Int, depth::Int, rng::AbstractRNG)
    memory = Float64[]
    ranges = fill(0:0, K, depth)
    return MemorizingSource{typeof(rng)}(rng, memory, ranges, 0)
end

function get_rng(s::MemorizingSource, scenario::Int, depth::Int)
    range = s.ranges[scenario, depth+1]
    new = false
    if range == 0:0
        range = s.furthest+1:s.furthest
        new = true
    end
    rng = MemorizingRNG(view(s.memory, range), 0, s)
    if new
        s.head = rng
    end
    return rng
end

function srand(s::MemorizingSource, seed)
    srand(s.rng, seed)
    fill!(s.ranges, 0:0)
    resize!(s.memory, 0)
    return s
end

function gen_rand!(r::MemorizingRNG{MemorizingSource{MersenneTwister}}, n::Integer)
    s = r.source
    if r === s.head
        orig = length(s.memory)
        if orig < s.furthest + n
            resize!(s.memory, orig+MTCacheLength)
            Base.Random.gen_rand(s.rng) # could be faster to use dsfmt_fill_array_close1_open2
            s.memory[orig+1:end] = s.rng.vals
            Base.Random.mt_setempty!(s.rng)
        end
        s.furthest += n
        r.vals = view(s.memory, first(first(r.vals.indexes)):s.furthest)
    else
        error("tried to gen_rand on an rng that is not the head")
    end
    return nothing
end

#=
function gen_one!(r::MemorizingRNG{S}) where S<: MemorizingSource
    s = r.source
    if r === s.head
        push!(s.memory, rand(s.rng, Close1Open2))
        r.vals = view(s.memory, first(first(r.vals.indexes)):length(r.vals))
    else
        error("tried to gen_rand on an rng that is not the head")
    end
    return nothing

end
=#
