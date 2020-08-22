using ARDESPOT
using Random

mt = MersenneTwister(1)

rng = MemorizingRNG(mt)

rand(rng)
rand(rng, Float64)
rand(rng, Int32)
rand(rng, [:a, :b, :c])
rand(rng, Int)
randn(rng)
rand(rng, 1:1_000_000)
randn(rng, (3,3))

@test isapprox(sum(rand(rng, Bool, 1_000_000))/1_000_000, 0.5, atol=0.001)
@test isapprox(sum(rand(rng, [1, 1, 1, 1, 0, 0, 0, 0], 1_000_000))/1_000_000, 0.5, atol=0.001)
