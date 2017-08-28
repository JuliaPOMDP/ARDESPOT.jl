struct DESPOT{S,A,O}
    scenarios::Vector{Vector{Pair{Int,S}}}
    children::Vector{Vector{Int}} # to children *ba nodes*
    parent_b::Vector{Int} # maps to parent *belief node*
    parent::Vector{Int} # maps to the parent *ba node*
    Delta::Vector{Int}
    mu::Vector{Float64} # needed for ba_mu, find_blocker, explore termination, next_best
    l::Vector{Float64} # needed to select action
    l_0::Vector{Float64} # needed for find_blocker, backup of l and mu
    obs::Vector{O}

    ba_children::Vector{Vector{Int}}
    ba_mu::Vector{Float64} # needed for next_best
    ba_rho::Vector{Float64} # needed for backup
    ba_action::Vector{A} # only for first level for right now
end

function DESPOT(p::DESPOTPlanner, b_0)
    root_scenarios = [i=>rand(p.rng, b_0) for i in 1:p.sol.K]
    l_0, mu_0 = root_rwdu_bounds(p, ScenarioBelief(root_scenarios, p.rs, 0, Nullable()))
    O = obs_type(p.pomdp)
    return DESPOT([root_scenarios],
                  [Int[]],
                  [0],
                  [0],
                  [0],
                  [mu_0],
                  [l_0],
                  [l_0],
                  Vector{O}(1),
                 
                  Vector{Int}[],
                  Float64[],
                  Float64[],
                  collect(iterator(actions(p.pomdp)))
                 )
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
            rng = get_rng(p.rs, first(scen), D.Delta[b])
            s = last(scen)
            if !isterminal(p.pomdp, s)
                sp, o, r = generate_sor(p.pomdp, s, a, rng)
                rsum += r
                bp = get(odict, o, 0)
                if bp == 0
                    push!(D.scenarios, Vector{Pair{Int, S}}())
                    bp = length(D.scenarios)
                    odict[o] = bp
                    push!(D.ba_children[ba], bp)
                end
                push!(D.scenarios[bp], first(scen)=>sp)
            end
        end

        rho = (rsum*discount(p.pomdp)^D.Delta[b]-length(D.scenarios[b])*p.sol.lambda)/p.sol.K
        push!(D.ba_rho, rho)

        nbps = length(odict)
        resize!(D, length(D.children) + nbps)
        for (o, bp) in odict
            D.obs[bp] = o

            D.children[bp] = Int[]
            D.parent_b[bp] = b
            D.parent[bp] = ba
            D.Delta[bp] = D.Delta[b]+1
            l_0, mu_0 = rwdu_bounds(D, bp, p)
            D.mu[bp] = mu_0
            D.l[bp] = l_0
            D.l_0[bp] = l_0
        end

        push!(D.ba_mu, D.ba_rho[ba] + sum(D.mu[bp] for bp in D.ba_children[ba]))
    end
end

get_belief(D::DESPOT, b::Int, rs::DESPOTRandomSource) = ScenarioBelief(D.scenarios[b], rs, D.Delta[b], Nullable(D.obs[b]))

function Base.resize!(D::DESPOT, n::Int)
    resize!(D.children, n)
    resize!(D.parent_b, n)
    resize!(D.parent, n)
    resize!(D.Delta, n)
    resize!(D.mu, n)
    resize!(D.l, n)
    resize!(D.l_0, n)
    resize!(D.obs, n)
end

"""
Return initial values of the *regularized* weighted discounted utility bounds (l_0 and mu_0)
"""
function rwdu_bounds(D::DESPOT, b::Int, p::DESPOTPlanner)
    L_0, U_0 = bounds(p.bounds, p.pomdp, get_belief(D, b, p.rs))
    l_0 = length(D.scenarios[b])/p.sol.K * discount(p.pomdp)^D.Delta[b] * L_0
    mu_0 = max(l_0, length(D.scenarios[b])/p.sol.K * discount(p.pomdp)^D.Delta[b] * U_0)
    return l_0, mu_0
end

function root_rwdu_bounds(p::DESPOTPlanner, b)
    L_0, U_0 = bounds(p.bounds, p.pomdp, b)
    l_0 = L_0
    mu_0 = max(l_0, U_0)
    return l_0, mu_0
end
