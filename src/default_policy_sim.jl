function branching_sim(pomdp::POMDP, policy::Policy, b::ScenarioBelief, steps::Integer)
    S = statetype(pomdp)
    O = obstype(pomdp)
    odict = Dict{O, Vector{Pair{Int, S}}}()

    if steps <= 0
        return 0.0
    end

    a = action(policy, b)

    r_sum = 0.0
    for (k, s) in b.scenarios
        if !isterminal(pomdp, s)
            rng = get_rng(b.random_source, k, b.depth)
            sp, o, r = generate_sor(pomdp, s, a, rng)

            if haskey(odict, o)
                push!(odict[o], k=>sp)
            else
                odict[o] = [k=>sp]
            end

            r_sum += r
        end
    end

    next_r = 0.0
    for (o, scenarios) in odict 
        bp = ScenarioBelief(scenarios, b.random_source, b.depth+1, o)
        if length(scenarios) == 1
            next_r += rollout(pomdp, policy, bp, steps-1)
        else
            next_r += branching_sim(pomdp, policy, bp, steps-1)
        end
    end

    return r_sum + discount(pomdp)*next_r
end

# once there is only one scenario left, just run a rollout
function rollout(pomdp::POMDP, policy::Policy, b0::ScenarioBelief, steps::Integer)
    @assert length(b0.scenarios) == 1
    disc = 1.0
    r_total = 0.0
    scenario_mem = copy(b0.scenarios)
    (k, s) = first(b0.scenarios)
    b = ScenarioBelief(scenario_mem, b0.random_source, b0.depth, b0._obs)

    while !isterminal(pomdp, s) && steps > 0
        a = action(policy, b)

        rng = get_rng(b.random_source, k, b.depth)
        sp, o, r = generate_sor(pomdp, s, a, rng)

        r_total += disc*r

        s = sp
        scenario_mem[1] = k=>s
        b = ScenarioBelief(scenario_mem, b.random_source, b.depth+1, o)

        disc *= discount(pomdp)
        steps -= 1
    end

    return r_total
end
