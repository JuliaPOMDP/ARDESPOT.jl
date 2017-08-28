abstract type DESPOTRandomSource end

check_consistency(rs::DESPOTRandomSource) = nothing

# this might be slow, but will wait until profiling to avoid premature optimization
struct MersenneSource <: DESPOTRandomSource
    advance::Int
    twisters::Vector{Vector{MersenneTwister}}
    use::MersenneTwister
end

function MersenneSource(K::Int, advance::Int, rng::AbstractRNG)
    @assert advance <= Base.Random.MTCacheLength
    twisters = [[MersenneTwister(rand(rng, UInt32))] for i in 1:K]
    return MersenneSource(advance, twisters, MersenneTwister(0))
end

function get_rng(rs::MersenneSource, scenario::Int, depth::Int)
    stream = rs.twisters[scenario]
    while length(stream) < depth+1
        new = copy(stream[end]) # <- probably slow
        new.idx += rs.advance
        Base.Random.reserve(new, rs.advance)
        push!(stream, new)
    end
    use = stream[depth+1]
    return copy!(rs.use, use)
end




struct FastMersenneStream
    twisters::Vector{MersenneTwister}
    spots::Vector{Int}
    hashs::Vector{UInt64}
    advance::Int
end

function FastMersenneStream(advance, rng::MersenneTwister)
    @assert advance <= Base.Random.MTCacheLength
    mt = MersenneTwister(rand(rng, UInt32))
    Base.Random.gen_rand(mt)
    return FastMersenneStream([mt], [0], [hash((mt.vals, 0))], advance)
end

function get_rng(stream::FastMersenneStream, depth::Int)
    twisters = stream.twisters
    spots = stream.spots
    while length(twisters) < depth+1
        new = twisters[end]
        spot = spots[end] + stream.advance
        if spot + stream.advance > Base.Random.MTCacheLength
            new = copy(new)
            Base.Random.gen_rand(new)
            spot = 0
        end
        push!(twisters, new)
        push!(spots, spot)
        push!(stream.hashs, hash((new.vals, spot)))
    end
    use = twisters[depth+1]
    use.idx = spots[depth+1]
    @assert use.idx < Base.Random.MTCacheLength
    @assert Base.Random.mt_avail(use) >= stream.advance
    return use
end

function check_consistency(rs::FastMersenneStream)
    for i in 1:length(rs.twisters)
        h = hash((rs.twisters[i].vals, rs.spots[i]))
        if h != rs.hashs[i]
            warn("FastMersenneStream was inconsistent - too many random numbers were drawn. Consider increasing the advance.")
        end
    end
end

mutable struct FastMersenneSource <: DESPOTRandomSource
    K::Int
    advance::Int
    streams::Vector{FastMersenneStream}
end

function FastMersenneSource(K::Int, advance::Int)
    return FastMersenneSource(K, advance, FastMersenneStream[])
end

get_stream(rs::FastMersenneSource, scenario::Int) = rs.streams[scenario]
get_rng(rs::DESPOTRandomSource, scenario::Int, depth::Int) = get_rng(get_stream(rs, scenario), depth)

function check_consistency(rs::FastMersenneSource)
    for s in rs.streams
        check_consistency(s)
    end
end

function Base.srand(rs::FastMersenneSource, seed)
    mt = MersenneTwister(seed)
    rs.streams = [FastMersenneStream(rs.advance, mt) for i in 1:rs.K]
    return rs
end







# For Debugging #
#################

struct SimpleMersenneSource <: DESPOTRandomSource
    twisters::Vector{Vector{MersenneTwister}}
end

function SimpleMersenneSource(K::Int)
    twisters = [[MersenneTwister(1)] for i in 1:K]
    return SimpleMersenneSource(twisters)
end

function get_rng(rs::SimpleMersenneSource, scenario::Int, depth::Int)
    stream = rs.twisters[scenario]
    while length(stream) < depth+1
        push!(stream, MersenneTwister(1))
    end
    return stream[depth+1]
end
