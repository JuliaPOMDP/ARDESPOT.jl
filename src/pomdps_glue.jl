solve(sol::DESPOTSolver, p::POMDP) = DESPOTPlanner(sol, p)

function action(p::DESPOTPlanner, b)
    srand(p.rs, rand(p.rng, UInt32))

    D = build_despot(p, b)

    check_consistency(p.rs)

    best_l = -Inf
    best_as = action_type(p.pomdp)[]
    for ba in D.children[1]
        l = mean(D.l[bnode] for bnode in D.ba_children[ba])
        if l > best_l
            best_l = l
            best_as = [D.ba_action[ba]]
        elseif l == best_l
            push!(best_as, D.ba_action[ba])
        end
    end
    best_a = rand(p.rng, best_as) # best_as will usually only have one entry, but we want to break the tie randomly
    return best_a
end

function updater(p::DESPOTPlanner)
    return SIRParticleFilter(p.pomdp, p.sol.K, rng=p.rng)
end
