import Random: CloseOpen01_64, CloseOpen12_64, FloatInterval, MT_CACHE_F

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
@inline reserve(r::MemorizingRNG, n::Integer) = mr_avail(r) < n && gen_rand!(r, n)

# precondition: !mr_empty(r)
@inline rand_inbounds(r::MemorizingRNG, ::Type{CloseOpen12_64}) = mr_pop!(r)
@inline rand_inbounds(r::MemorizingRNG, ::Type{CloseOpen01_64}) = rand_inbounds(r, CloseOpen12_64) - 1.0
@inline rand_inbounds(r::MemorizingRNG) = rand_inbounds(r, CloseOpen01_64)

Random.rng_native_52(rng::MemorizingRNG) = Random.rng_native_52(rng.source)

function rand(r::MemorizingRNG, ::Union{I, Type{I}}) where I <: FloatInterval
    reserve_1(r)
    rand_inbounds(r, I)
end

# rand(r::MemorizingRNG, ::Type{Float64}) = rand(r, CloseOpen01)

function gen_rand!(r::MemorizingRNG{MersenneTwister}, n::Integer)
    len = length(r.memory)
    if len < r.idx + n
        resize!(r.memory, len+MT_CACHE_F)
        Random.gen_rand(r.source) # could be faster to use dsfmt_fill_array_close1_open2
        r.memory[len+1:end] = r.source.vals
        Random.mt_setempty!(r.source)
    end
    r.finish = length(r.memory)
    return r
end
