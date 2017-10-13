importall Base.Random
import Base.Random: CloseOpen, Close1Open2, FloatInterval, MTCacheLength

mutable struct MemorizingRNG{S} <: AbstractRNG
    memory::Vector{Float64}
    start::Int
    finish::Int
    idx::Int
    source::S
end

MemorizingRNG(source) = MemorizingRNG(Float64[], 1, 0, 0, source)

# Low level API (copied from MersenneTwister)
@inline mr_avail(r::MemorizingRNG) = r.finish - r.idx
@inline mr_empty(r::MemorizingRNG) = r.idx == r.finish
@inline mr_pop!(r::MemorizingRNG) = @inbounds return r.memory[r.idx+=1]

@inline reserve_1(r::MemorizingRNG) = mr_empty(r) && gen_rand!(r, 1)

# precondition: !mr_empty(r)
@inline rand_inbounds(r::MemorizingRNG, ::Type{Close1Open2}) = mr_pop!(r)
@inline rand_inbounds(r::MemorizingRNG, ::Type{CloseOpen}) = rand_inbounds(r, Close1Open2) - 1.0
@inline rand_inbounds(r::MemorizingRNG) = rand_inbounds(r, CloseOpen)


function rand(r::MemorizingRNG, ::Type{I}) where I <: FloatInterval
    reserve_1(r)
    return rand_inbounds(r, I)
end

function gen_rand!(r::MemorizingRNG{MersenneTwister}, n::Integer)
    len = length(r.memory)
    if len < r.idx + n
        resize!(r.memory, len+MTCacheLength)
        Base.Random.gen_rand(r.source) # could be faster to use dsfmt_fill_array_close1_open2
        r.memory[len+1:end] = r.source.vals
        Base.Random.mt_setempty!(r.source)
    end
    r.finish = length(r.memory)
    return r
end
