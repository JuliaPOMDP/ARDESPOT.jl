rng = MemorizingRNG(MersenneTwister(12))

a = rand(rng)
rand(rng)
rand(rng)
rand(rng)

rand(rng, Float64)

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

src = MemorizingSource(1, 2, MersenneTwister(12), grow_reserve=false)

rng = ARDESPOT.get_rng(src, 1, 1)
r1 = rand(rng)
rng2 = ARDESPOT.get_rng(src, 1, 2)
r2 = rand(rng2)
rng = ARDESPOT.get_rng(src, 1, 1)
@test r1 == rand(rng)
r3 = rand(rng)
@test src.move_count == 1
rng2 = ARDESPOT.get_rng(src, 1, 2)
@test r2 == rand(rng2)
rng = ARDESPOT.get_rng(src, 1, 1)
@test r1 == rand(rng)
@test r3 == rand(rng)

@test src.move_count == 1

@test_logs (:warn,) ARDESPOT.check_consistency(src)

# grow reserve
src = MemorizingSource(1, 4, MersenneTwister(12))

rng = ARDESPOT.get_rng(src, 1, 1)
r1 = rand(rng)
rng2 = ARDESPOT.get_rng(src, 1, 2)
r2 = rand(rng2)
rng = ARDESPOT.get_rng(src, 1, 1)
@test r1 == rand(rng)
r3 = rand(rng)
@test src.move_count == 1
@test src.min_reserve == 2
rng2 = ARDESPOT.get_rng(src, 1, 2)
@test r2 == rand(rng2)
rng = ARDESPOT.get_rng(src, 1, 1)
@test r1 == rand(rng)
@test r3 == rand(rng)

# create a new one, but don't get any numbers until creating the next - should have automatically reserved enough
rng3 = ARDESPOT.get_rng(src, 1, 3)
rng4 = ARDESPOT.get_rng(src, 1, 4)
r4 = rand(rng4)
rng3 = ARDESPOT.get_rng(src, 1, 3)
r5 = rand(rng3)
r6 = rand(rng3)

# check that this didn't trigger a move
@test src.move_count == 1
