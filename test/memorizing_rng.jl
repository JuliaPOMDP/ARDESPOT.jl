using ARDESPOT
using Random

mt = MersenneTwister(1)

rng = MemorizingRNG(mt)

rand(rng)
rand(rng, Float64)
rand(rng, [:a, :b, :c])
# rand(rng, Int) # XXX this doesn't work
randn(rng)
