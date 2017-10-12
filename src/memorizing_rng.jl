importall Base.Random
import Base.Random: CloseOpen, Close1Open2, FloatInterval

mutable struct MemorizingRNG{S, V<:AbstractVector{Float64}} <: AbstractRNG
    vals::V
    idx::Int
    source::S
end

MemorizingRNG(source) = MemorizingRNG(Float64[], 0, source)

# Low level API (copied from MersenneTwister)
@inline mr_avail(r::MemorizingRNG) = length(r.vals) - r.idx
@inline mr_empty(r::MemorizingRNG) = r.idx == length(r.vals)
@inline mr_pop!(r::MemorizingRNG) = @inbounds return r.vals[r.idx+=1]

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
    orig = length(r.vals)
    new = orig+n
    resize!(r.vals, new)
    Base.Random.rand_AbstractArray_Float64!(r.source, view(r.vals, orig+1:new), new-orig, Close1Open2)
end

function gen_one!(r::MemorizingRNG{MersenneTwister})
    push!(r.vals, rand(r.source, Close1Open2))
end
