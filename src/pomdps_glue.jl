POMDPs.solve(sol::DESPOTSolver, p::POMDP) = DESPOTPlanner(sol, p)

function POMDPModelTools.action_info(p::DESPOTPlanner, b)
    info = Dict{Symbol, Any}()
    try
        Random.seed!(p.rs, rand(p.rng, UInt32))

        D = build_despot(p, b)

        if p.sol.tree_in_info
            info[:tree] = D
        end

        check_consistency(p.rs)

        if isempty(D.children[1]) && D.U[1] <= D.l_0[1]
            throw(NoGap(D.l_0[1]))
        end

        best_l = -Inf
        best_as = actiontype(p.pomdp)[]
        for ba in D.children[1]
            l = ba_l(D, ba)
            if l > best_l
                best_l = l
                best_as = actiontype(p.pomdp)[D.ba_action[ba]]
            elseif l == best_l
                push!(best_as, D.ba_action[ba])
            end
        end

        return rand(p.rng, best_as)::actiontype(p.pomdp), info # best_as will usually only have one entry, but we want to break the tie randomly
    catch ex
        return default_action(p.sol.default_action, p.pomdp, b, ex)::actiontype(p.pomdp), info
    end
end

POMDPs.action(p::DESPOTPlanner, b) = first(action_info(p, b))::actiontype(p.pomdp)

ba_l(D::DESPOT, ba::Int) = D.ba_rho[ba] + sum(D.l[bnode] for bnode in D.ba_children[ba])

POMDPs.updater(p::DESPOTPlanner) = SIRParticleFilter(p.pomdp, p.sol.K, rng=p.rng)

function Random.seed!(p::DESPOTPlanner, seed)
    Random.seed!(p.rng, seed)
    return p
end
