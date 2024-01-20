struct LDPolicy{M<:POMDP,S}<:Policy
    m::M
    particle_dict::Dict{S,Float64}
    act::Int64
    planner::DPWPlanner
end

function LDPolicy(m::LightDark1D{S}) where S
    solver = DPWSolver(n_iterations=50, depth=20, exploration_constant=5.0)
    planner = solve(solver, UnderlyingMDP(m))
    return LDPolicy(m,Dict{S,Float64}(),-1,planner)
end

##Tyler's map_bel 
@inline function get_incr!(h::Dict{K,V}, key::K, v) where {K,V} # modified from dict.jl
    index = Base.ht_keyindex2!(h, key)

    v = convert(V, v)
    if index > 0
        h.age += 1
        return h.vals[index] += 1
    end

    age0 = h.age
    if h.age != age0
        index = Base.ht_keyindex2!(h, key)
    end
    if index > 0
        h.age += 1
        @inbounds h.keys[index] = key
        @inbounds h.vals[index] = v
    else
        @inbounds Base._setindex!(h, v, key, -index)
    end
    return v
end

function map_bel(b::AbstractParticleBelief, pol)
    empty!(pol.particle_dict)
    dict = pol.particle_dict
    max_o = 0.0
    # max_state = first(particles(b))
    max_state = pol.m.state1
    for (p,w) in weighted_particles(b)
        n = get_incr!(dict, p, w)
        if n > max_o
            max_o = n
            max_state = p
        end
    end
    return max_state
end

function POMDPs.action(policy::LDPolicy,s::Union{ParticleCollection,ScenarioBelief})
    max_p = map_bel(s,policy)
    return POMDPs.action(policy,max_p)
end

function POMDPs.action(policy::LDPolicy,s::POMDPModels.LDNormalStateDist)
    max_p = map_bel(s,policy)
    return POMDPs.action(policy,max_p)
end