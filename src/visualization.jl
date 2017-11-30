function D3Trees.D3Tree(D::DESPOT; title="DESPOT Tree", kwargs...)
    lenb = length(D.children)
    lenba = length(D.ba_children)
    len = lenb + lenba
    K = length(D.scenarios[1])
    children = Vector{Vector{Int}}(len)
    text = Vector{String}(len)
    tt = fill("", len)
    link_style = fill("", len)
    L = calc_L(D)
    for b in 1:lenb
        children[b] = D.children[b] .+ lenb
        text[b] = @sprintf("""
                           o:%s (|Φ|:%3d)
                           L:%6.2f, U:%6.2f
                           l:%6.2f, μ:%6.2f, l₀:%6.2f""",
                           b==1 ? "<root>" : string(D.obs[b]),
                           length(D.scenarios[b]),
                           L[b],
                           D.U[b],
                           D.l[b],
                           D.mu[b],
                           D.l_0[b]
                          )
        tt[b] = """
                o: $(b==1 ? "<root>" : string(D.obs[b]))
                |Φ|: $(length(D.scenarios[b]))
                L: $(L[b])
                U: $(D.U[b])
                l: $(D.l[b])
                μ: $(D.mu[b])
                l₀: $(D.l_0[b])
                $(length(D.children[b])) children
                """
        link_width = 20.0*sqrt(length(D.scenarios[b])/K)
        link_style[b] = "stroke-width:$link_width"
        for ba in D.children[b]
            link_style[ba+lenb] = "stroke-width:$link_width"
        end

        for ba in D.children[b]
            weighted_sum_U = 0.0
            for bp in D.ba_children[ba]
                weighted_sum_U += length(D.scenarios[bp]) * D.U[bp]
            end
            U = (D.ba_Rsum[ba] + infer_discount(D) * weighted_sum_U) / length(D.scenarios[b])
            children[ba+lenb] = D.ba_children[ba]
            text[ba+lenb] = @sprintf("""
                                     a:%s (ρ:%6.2f)
                                     L:%6.2f, U:%6.2f,
                                     l:%6.2f μ:%6.2f""",
                                     D.ba_action[ba], D.ba_rho[ba],
                                     L[ba+lenb], U,
                                     ba_l(D, ba), D.ba_mu[ba])
            tt[ba+lenb] = """
                          a: $(D.ba_action[ba])
                          ρ: $(D.ba_rho[ba])
                          L: $(L[ba+lenb])
                          U: $U
                          l: $(ba_l(D, ba))
                          μ: $(D.ba_mu[ba])
                          $(length(D.ba_children[ba])) children
                          """
        end
    end
    return D3Tree(children;
                  text=text,
                  tooltip=tt,
                  link_style=link_style,
                  title=title,
                  kwargs...
                 )
end

Base.show(io::IO, mime::MIME"text/html", D::DESPOT) = show(io, mime, D3Tree(D))
Base.show(io::IO, mime::MIME"text/plain", D::DESPOT) = show(io, mime, D3Tree(D))

"""
Return a vector of lower bounds L of length lenb+lenba, with b nodes first followed by ba nodes.
"""
function calc_L(D::DESPOT)
    lenb = length(D.children)
    lenba = length(D.ba_children)
    if lenb == 1
        @assert lenba == 0
        return [D.l_0[1]]
    end
    len = lenb + lenba
    cache = fill(NaN, len)
    disc = infer_discount(D)
    fill_L!(cache, D, 1, disc)
    return cache
end

function infer_discount(D::DESPOT)
    # @assert !isempty(D.children[1])
    # K = length(D.scenarios[0])
    # firstba = first(D.children[1])
    # lambda = D.ba_rsum[firstba]/K - D.ba_rho[firstba]
    disc = D._discount
    return disc
end


"""
Fill all the elements of the cache for b and children of b and return L[b]
"""
function fill_L!(cache::Vector{Float64}, D::DESPOT, b::Int, disc::Float64)
    K = length(D.scenarios[1])
    lenb = length(D.children)
    if isempty(D.children[b])
        L = D.l_0[b]*K/(length(D.scenarios[b])*disc^D.Delta[b])
        cache[b] = L
        return L
    else
        max_L = -Inf
        for ba in D.children[b]
            weighted_sum_L = 0.0
            for bp in D.ba_children[ba]
                weighted_sum_L += length(D.scenarios[bp]) * fill_L!(cache, D, bp, disc)
            end
            new_L = (D.ba_Rsum[ba] + disc * weighted_sum_L) / length(D.scenarios[b])
            cache[lenb+ba] = new_L
            max_L = max(max_L, new_L)
        end
        cache[b] = max_L
        return max_L
    end
end
