struct DESPOT{S,A,O}
    scenarios::Vector{Vector{Pair{Int,S}}}
    children::Vector{Vector{Int}} # to children *ba nodes*
    parent_b::Vector{Int} # maps to parent *belief node*
    parent::Vector{Int} # maps to the parent *ba node*
    Delta::Vector{Int}
    mu::Vector{Float64} # needed for ba_mu, excess_uncertainty
    l::Vector{Float64} # needed to select action, excess_uncertainty
    U::Vector{Float64} # needed for blocking
    l_0::Vector{Float64} # needed for find_blocker, backup of l and mu
    obs::Vector{O}

    ba_children::Vector{Vector{Int}}
    ba_mu::Vector{Float64} # needed for next_best
    ba_rho::Vector{Float64} # needed for backup
    ba_Rsum::Vector{Float64} # needed for backup
    ba_action::Vector{A}

    _discount::Float64 # for inferring L in visualization
end

function DESPOT(p::DESPOTPlanner, b_0)
    S = state_type(p.pomdp)
    A = action_type(p.pomdp)
    O = obs_type(p.pomdp)
    root_scenarios = [i=>rand(p.rng, b_0) for i in 1:p.sol.K]
    
    scenario_belief = ScenarioBelief(root_scenarios, p.rs, 0, Nullable{O}())
    L_0, U_0 = bounds(p.bounds, p.pomdp, scenario_belief)

    if p.sol.bounds_warnings
        bounds_sanity_check(p.pomdp, scenario_belief, L_0, U_0)
    end

    return DESPOT{S,A,O}([root_scenarios],
                         [Int[]],
                         [0],
                         [0],
                         [0],
                         [max(L_0, U_0 - p.sol.lambda)],
                         [L_0],
                         [U_0],
                         [L_0],
                         Vector{O}(1),
                 
                         Vector{Int}[],
                         Float64[],
                         Float64[],
                         Float64[],
                         A[],
                         discount(p.pomdp)
                 )
end

function expand!(D::DESPOT, b::Int, p::DESPOTPlanner)
    S = state_type(p.pomdp)
    A = action_type(p.pomdp)
    O = obs_type(p.pomdp)
    odict = Dict{O, Int}()

    for a in iterator(actions(p.pomdp))
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
                end
                push!(D.scenarios[bp], first(scen)=>sp)
            end
        end

        push!(D.ba_children, collect(values(odict)))
        ba = length(D.ba_children)
        push!(D.ba_action, a)
        push!(D.children[b], ba)
        rho = rsum*discount(p.pomdp)^D.Delta[b]/p.sol.K - p.sol.lambda
        push!(D.ba_rho, rho)
        push!(D.ba_Rsum, rsum)

        nbps = length(odict)
        resize!(D, length(D.children) + nbps)
        for (o, bp) in odict
            D.obs[bp] = o
            D.children[bp] = Int[]
            D.parent_b[bp] = b
            D.parent[bp] = ba
            D.Delta[bp] = D.Delta[b]+1

            scenario_belief = get_belief(D, bp, p.rs)
            L_0, U_0 = bounds(p.bounds, p.pomdp, scenario_belief)

            if p.sol.bounds_warnings
                bounds_sanity_check(p.pomdp, scenario_belief, L_0, U_0)
            end

            l_0 = length(D.scenarios[bp])/p.sol.K * discount(p.pomdp)^D.Delta[bp] * L_0
            mu_0 = max(l_0, length(D.scenarios[bp])/p.sol.K * discount(p.pomdp)^D.Delta[bp] * U_0 - p.sol.lambda)

            D.mu[bp] = mu_0
            D.U[bp] = U_0
            D.l[bp] = l_0 # = max(l_0, l_0 - p.sol.lambda)
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
    resize!(D.U, n)
    resize!(D.l_0, n)
    resize!(D.obs, n)
end
