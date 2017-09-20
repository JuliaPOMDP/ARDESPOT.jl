function build_despot(p::DESPOTPlanner, b_0)
    D = DESPOT(p, b_0)
    b = 1
    trial = 1
    start = CPUtime_us()

    while D.mu[1]-D.l[1] > p.sol.epsilon_0 &&
          CPUtime_us()-start < p.sol.T_max*1e6 &&
          trial <= p.sol.max_trials
        b = explore!(D, 1, p)
        backup!(D, b, p)
        trial += 1
    end

    return D
end

function explore!(D::DESPOT, b::Int, p::DESPOTPlanner)
    while D.Delta[b] <= p.sol.D && excess_uncertainty(D, b, p) > 0.0 # && !prune!(D, b, p)
        if isempty(D.children[b]) # a leaf
            expand!(D, b, p)
        end
        b = next_best(D, b, p)
    end
    if D.Delta[b] > p.sol.D
        make_default!(D, b)
    end
    return b
end

function prune!(D::DESPOT, b::Int, p::DESPOTPlanner)
    x = b
    blocked = false
    while x != 1
        n = find_blocker(D, x, p)
        if n > 0
            make_default!(D, x)
            backup!(D, x, p)
            blocked = true
        else
            break
        end
        x = D.parent_b[x]
    end
    return blocked
end

function find_blocker(D::DESPOT, b::Int, p::DESPOTPlanner)
    len = 1
    bp = D.parent_b[b] # Note: unlike the normal use of bp, here bp is a parent following equation (12)
    while bp != 1
        left_side_eq_12 = length(D.scenarios[bp])/p.sol.K*discount(p.pomdp)^D.Delta[bp]*D.U[bp] - D.l_0[bp]
        if left_side_eq_12 <= p.sol.lambda * len
            return bp
        else
            bp = D.parent_b[bp]
            len += 1
        end
    end
    return 0 # no blocker
end

function make_default!(D::DESPOT, b::Int)
    l_0 = D.l_0[b]
    D.mu[b] = l_0
    D.l[b] = l_0
end

function backup!(D::DESPOT, b::Int, p::DESPOTPlanner)
    # Note: maybe this could be sped up by just calculating the change in the one mu and l corresponding to bp, rather than summing up over all bp
    while b != 1 
        ba = D.parent[b]
        b = D.parent_b[b]

        # https://github.com/JuliaLang/julia/issues/19398
        #=
        D.ba_mu[ba] = D.ba_rho[ba] + sum(D.mu[bp] for bp in D.ba_children[ba])
        =#
        sum_mu = 0.0
        for bp in D.ba_children[ba]
            sum_mu += D.mu[bp]
        end
        D.ba_mu[ba] = D.ba_rho[ba] + sum_mu

        #=
        max_mu = maximum(D.ba_rho[ba] + sum(D.mu[bp] for bp in D.ba_children[ba]) for ba in D.children[b])
        max_l = maximum(D.ba_rho[ba] + sum(D.l[bp] for bp in D.ba_children[ba]) for ba in D.children[b])
        =#
        max_U = -Inf
        max_mu = -Inf
        max_l = -Inf
        for ba in D.children[b]
            weighted_sum_U = 0.0
            sum_mu = 0.0
            sum_l = 0.0
            for bp in D.ba_children[ba]
                weighted_sum_U += length(D.scenarios[bp]) * D.U[bp]
                sum_mu += D.mu[bp]
                sum_l += D.l[bp]
            end
            new_U = (D.ba_Rsum[ba] + discount(p.pomdp) * weighted_sum_U)/length(D.scenarios[b])
            new_mu = D.ba_rho[ba] + sum_mu
            new_l = D.ba_rho[ba] + sum_l
            max_U = max(max_U, new_U)
            max_mu = max(max_mu, new_mu)
            max_l = max(max_l, new_l)
        end

        l_0 = D.l_0[b]
        D.U[b] = max_U
        D.mu[b] = max(l_0, max_mu)
        D.l[b] = max(l_0, max_l)
    end
end

function next_best(D::DESPOT, b::Int, p::DESPOTPlanner)
    ai = indmax(D.ba_mu[ba] for ba in D.children[b])
    ba = D.children[b][ai]
    zi = indmax(excess_uncertainty(D, bp, p) for bp in D.ba_children[ba])
    return D.ba_children[ba][zi]
end

function excess_uncertainty(D::DESPOT, b::Int, p::DESPOTPlanner)
    return D.mu[b]-D.l[b] - length(D.scenarios[b])/p.sol.K * p.sol.xi * (D.mu[1]-D.l[1])
end
