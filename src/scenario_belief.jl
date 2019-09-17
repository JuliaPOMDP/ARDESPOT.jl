struct ScenarioBelief{S, O, RS<:DESPOTRandomSource} <: AbstractParticleBelief{S}
    scenarios::Vector{Pair{Int,S}}
    random_source::RS
    depth::Int
    _obs::O
end

rand(rng::AbstractRNG, b::ScenarioBelief) = last(b.scenarios[rand(rng, 1:length(b.scenarios))])
ParticleFilters.particles(b::ScenarioBelief) = (last(p) for p in b.scenarios)
ParticleFilters.n_particles(b::ScenarioBelief) = length(b.scenarios)
ParticleFilters.weight(b::ScenarioBelief, s) = 1/length(b.scenarios)
ParticleFilters.particle(b::ScenarioBelief, i) = last(b.scenarios[i])
ParticleFilters.weight_sum(b::ScenarioBelief) = 1.0
ParticleFilters.weights(b::ScenarioBelief) = (1/length(b.scenarios) for p in b.scenarios)
ParticleFilters.weighted_particles(b::ScenarioBelief) = (last(p)=>1/length(b.scenarios) for p in b.scenarios)
POMDPs.pdf(b::ScenarioBelief{S}, s::S) where S = sum(p==s for p in particles(b))/length(b.scenarios) # this is slow
POMDPs.mean(b::ScenarioBelief) = mean(last, b.scenarios)
POMDPs.currentobs(b::ScenarioBelief) = b._obs
@deprecate previous_obs POMDPs.currentobs
POMDPs.history(b::ScenarioBelief) = tuple((o=currentobs(b),))

initialize_belief(::PreviousObservationUpdater, b::ScenarioBelief) = previous_obs(b)
