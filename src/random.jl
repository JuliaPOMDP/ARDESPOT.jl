abstract type DESPOTRandomSource end

# this might be slow, but will wait until profiling to avoid premature optimization
struct MersenneSource <: DESPOTRandomSource
    advance::Int
    twisters::Vector{Vector{MersenneTwister}}
    use::MersenneTwister
end

function MersenneSource(K::Int, advance::Int, rng::AbstractRNG)
    @assert advance < Base.Random.MTCacheLength
    twisters = [[MersenneTwister(rand(rng, UInt32))] for i in 1:K]
    return MersenneSource(advance, twisters, MersenneTwister(0))
end

function get_rng(rs::MersenneSource, scenario::Int, depth::Int)
    stream = rs.twisters[scenario]
    while length(stream) < depth+1
        new = copy(stream[end]) # <- probably slow
        Base.Random.reserve(new, rs.advance)
        new.idx += rs.advance
        push!(stream, new)
    end
    return copy!(rs.use, stream[depth+1])
end
