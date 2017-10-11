rng = MemorizingRNG(Float64[], 0, MersenneTwister(12))

a = rand(rng)
rand(rng)
rand(rng)
rand(rng)

rng.idx=0
@test rand(rng) == a

randn(rng)

rng.idx=0
b = randn(rng, 2)
randn(rng, 2)
randn(rng, 2)
randn(rng, 2)
rng.idx=0
@test b == randn(rng, 2)
