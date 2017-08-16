struct DESPOT{S, RS<:RandomStream}
    scenarios::Vector{Vector{Pair{Int,S}}}
    children::Vector{Vector{Int}} # to children *ba nodes*
    parent::Vector{Int} # maps to parent *belief node*
    parent_ba::Vector{Int} # maps to the parent *ba node*
    Delta::Vector{Int}
    mu::Vector{Float64} # needed for ba_mu, find_blocker, explore termination, next_best
    l::Vector{Float64} # needed to select action
    l_0::Vector{Float64} # needed for find_blocker, backup of l and mu

    ba_children{Vector{Vector{Int}}}
    ba_mu::Vector{Float64} # needed for next_best
    ba_rho::Vector{Float64} # needed for backup

    random_streams::RS
end

function expand!(D::DESPOT, b::Int, p::DESPOTPlanner)
    S = state_type(p.pomdp)
    A = action_type(p.pomdp)
    O = obs_type(p.pomdp)
    odict = Dict{O, Int}()

    for a in iterator(actions(p.pomdp))
        push!(D.ba_children, Int[])
        ba = length(D.ba_children)
        push!(D.children[b], ba)
        empty!(odict)
        rsum = 0.0

        for scen in D.scenarios[b]
            rng = get_rng(D, b, first(scen))
            sp, o, r = generate_sor(s, a, rng)
            rsum += r
            bp = get(odict, o, 0)
            if bp == 0
                bp = length(D.scenarios)+1
                odict[o] = bp
                push!(D.ba_children[ba], bp)
                D.scenarios[bp] = Vector{Pair{Int, S}}()
            end
            push!(D.scenarios[bp], first(scen)=>sp)
        end

        rho = (rsum*discount(p.pomdp)^D.Delta[b]-length(D.scenarios[b])*p.sol.lambda)/p.sol.K
        push!(D.ba_rho, rho)

        nbps = length(odict)
        resize!(D, length(D.children) + nbps)
        for bp in values(odict)
            D.children[bp] = Int[]
            D.parent[bp] = b
            D.parent_ba[bp] = ba
            D.Delta[bp] = D.Delta[b]+1
            L_0, U_0 = bounds(p.bounds, belief_node)
            l_0 = length(D.scenarios[bp])/p.sol.K * discount(p.pomdp)^D.Delta[bp] * L_0
            D.l_0[bp] = l_0
            D.l[bp] = l_0
            D.mu[bp] = max(l_0, length(D.scenarios[bp])/p.sol.K * discount(p.pomdp)^D.Delta[bp] * U_0)
        end

        ba_mu[ba] = ba_rho[ba] + sum(D.mu[bp] for bp in D.ba_children[ba])
    end
end

function resize!(D::DESPOT, n::Int)
    resize!(D.children, n)
    resize!(D.parent, n)
    resize!(D.Delta, n)
    resize!(D.mu, n)
    resize!(D.l, n)
    resize!(D.E, n)
end
