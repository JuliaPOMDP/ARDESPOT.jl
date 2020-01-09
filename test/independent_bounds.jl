@testset "Independent Bounds" begin
    m = BabyPOMDP()
    rs = MemorizingSource(1,1,MersenneTwister(37))
    sb = ScenarioBelief([1=>true], rs, 0, false)
    b = IndependentBounds(0.0, -1e-5)
    @test bounds(b, m, sb) == (0.0, -1e-5)
    b = IndependentBounds(0.0, -1e-5, consistency_fix_thresh=1e-5)
    @test bounds(b, m, sb) == (0.0, 0.0)
    b = IndependentBounds(0.0, -1e-4, consistency_fix_thresh=1e-5)
    @test bounds(b, m, sb) == (0.0, -1e-4)
end
