function build_despot(p::DESPOTPlanner, b_0)
    D = DESPOT(b_0)
    b = 1
    start = CPUtime_us()
    while D.mus[b]-D.ls[b] > p.sol.epsilon_0 && CPUTime_us()-start < p.sol.T_max*1000
        b = explore(D, b, p)
        backup!(D, b, p)
    end

    return D
end

function explore!(D::DESPOT, b::Int, p::DESPOTPlanner)
    while D.Delta[b] <= p.sol.D && excess_uncertainty(D, b, p) > 0.0 && !prune!(D, b, p)
        if isempty(D.children[b]) # a leaf
            expand!(D, b, p)
        end
        b = next_best(D, b)
    end
    if D.Delta[b] > p.sol.D
        make_default!(D, b)
    end
    return b
end

function prune!(D::DESPOT, b::Int, p::DESPOTPlanner)
    blocked = false
    while b != 1
        n = find_blocker(D, b, p)
        if n > 0
            make_default!(D, n)
            backup!(D, n, p)
            blocked = true
        else
            break
        end
    end
    return blocked
end

function find_blocker(D::DESPOT, b::Int, p::DESPOTPlanner)
    len = 1
    bp = D.parent[b] # Note: unlike the normal use of bp, here bp is a parent following equation (12)
    while bp != 1
        if D.mu[bp] - D.l_0[bp] <= p.sol.lambda * len
            return bp
        else
            bp = D.parent[bp]
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
        ba = D.parent_ba[b]
        b = D.parent[b]

        D.ba_mu[ba] = ba_rho[ba] + sum(D.mu[bp] for bp in D.ba_children[ba])

        max_mu = maximum(D.ba_rho[ba] + sum(D.mu[bp] for bp in D.ba_children[ba]) for ba in D.children[b])
        max_l = maximum(D.ba_rho[ba] + sum(D.l[bp] for bp in D.ba_children[ba]) for ba in D.children[b])

        l_0 = D.l_0[b]
        D.mu[b] = max(l_0, max_mu)
        D.l[b] = max(l_0, max_l)
    end
end

function next_best(D::DESPOT, b::Int, p::DESPOTPlanner)
    ai = argmax(D.ba_mu[b])
    ba = D.children[b][ai]
    zi = argmax(excess_uncertainty(D, bp, p) for bp in D.ba_children[ba])
    return D.ba_children[ba][zi]
end

function excess_uncertainty(D::DESPOT, b::Int, p::DESPOTPlanner)
    return D.mu[b]-D.l[b] - length(D.scenarios[b])/p.sol.K * p.sol.xi * (D.mu[1]-D.l[1])
end
