include("memorizing_rng.jl")

mutable struct MemorizingSource{RNG<:AbstractRNG} <: DESPOTRandomSource
    rng::RNG
    rngs::Vector{Vector{MemorizingRNG{MersenneTwister, Vector{Float64}}}}
end

function MemorizingSource(K::Integer, rng::AbstractRNG)
    return MemorizingSource(rng, fill([MemorizingRNG(rng)], K))
end

function get_rng(s::MemorizingSource, scenario::Int, depth::Int)
    stream = s.rngs[scenario]
    while length(stream) < depth+1
        push!(stream, MemorizingRNG(s.rng))
    end
    use = stream[depth+1]
    use.idx = 0
    return use
end

function srand(s::MemorizingSource, seed)
    srand(s.rng, seed)
    for i in 1:length(s.rngs)
        s.rngs[i] = [MemorizingRNG(s.rng)]
    end
    return s
end
