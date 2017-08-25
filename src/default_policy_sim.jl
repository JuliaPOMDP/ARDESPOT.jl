struct ScenarioSimulator{RS<:DESPOTRandomSource} <: Simulator
    random_source::RS
    scenario::Int
    start_depth::Int
    steps::Int
end

function simulate(sim::ScenarioSimulator, pomdp::POMDP, policy::Policy, updater::Updater, init_belief::ScenarioBelief, init_state)

    # stream = get_stream(sim.random_source, sim.scenario)

    b = initialize_belief(updater, init_belief)
    s = init_state

    step = 1

    disc = 1.0
    r_total = 0.0

    while !isterminal(pomdp, s) && step <= sim.steps
        a = action(policy, b)

        # rng = get_rng(stream, sim.start_depth + step - 1)
        rng = get_rng(sim.random_source, sim.scenario, sim.start_depth + step - 1)
        sp, o, r = generate_sor(pomdp, s, a, rng)

        r_total += disc*r

        s = sp

        bp = update(updater, b, a, o)
        b = bp

        disc *= discount(pomdp)
        step += 1
    end

    return r_total
end
