function D3Trees.D3Tree(D::DESPOT; title="DESPOT Tree", kwargs...)
    lenb = length(D.children)
    lenba = length(D.ba_children)
    len = lenb + lenba
    K = length(D.scenarios[1])
    children = Vector{Vector{Int}}(len)
    text = Vector{String}(len)
    tt = fill("", len)
    link_style = fill("", len)
    for b in 1:lenb
        children[b] = D.children[b] .+ lenb
        text[b] = @sprintf("""
                           o:%s (|Φ|:%3d)
                           U:%6.2f
                           l:%6.2f, μ:%6.2f, l₀:%6.2f""",
                           b==1 ? "<root>" : string(D.obs[b]),
                           length(D.scenarios[b]),
                           D.U[b],
                           D.l[b],
                           D.mu[b],
                           D.l_0[b]
                          )
        tt[b] = """
                o: $(b==1 ? "<root>" : string(D.obs[b]))
                |Φ|: $(length(D.scenarios[b]))
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
    end
    for ba in 1:lenba
        children[ba+lenb] = D.ba_children[ba]
        text[ba+lenb] = @sprintf("""
                                 a:%s (ρ:%6.2f)
                                 l:%6.2f μ:%6.2f""",
                                 D.ba_action[ba], D.ba_rho[ba], ba_l(D, ba), D.ba_mu[ba])
        tt[ba+lenb] = """
                      a: $(D.ba_action[ba])
                      ρ: $(D.ba_rho[ba])
                      l: $(ba_l(D, ba))
                      μ: $(D.ba_mu[ba])
                      $(length(D.ba_children[ba])) children
                      """
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
