struct ScenarioBelief{S, O, RS<:DESPOTRandomSource} <: AbstractParticleBelief{S}
    scenarios::Vector{Pair{Int,S}}
    random_source::RS
    depth::Int
    _obs::O # this might be replaced by ao_history later - use previous_obs to access
end

rand(rng::AbstractRNG, b::ScenarioBelief) = b.scenarios[rand(rng, 1:length(b.scenarios))]
ParticleFilters.particles(b::ScenarioBelief) = (last(p) for p in b.scenarios)
ParticleFilters.n_particles(b::ScenarioBelief) = length(b.scenarios)
ParticleFilters.weight(b::ScenarioBelief, s) = 1/length(b.scenarios)
previous_obs(b::ScenarioBelief) = b._obs

initialize_belief(::PreviousObservationUpdater, b::ScenarioBelief) = previous_obs(b)
