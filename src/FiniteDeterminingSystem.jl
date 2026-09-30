#__________________________________________________________________________________________
# ------------- FINITE AND INFINITESIMAL DETERMINING SYSTEMS (full chain rule) -------------
#
# Total derivative along solutions of an unknown function F:
#
#     D(F) = F_t + sum_j F_{x_j} * f_j(t,x,u,p) + sum_k F_{u_k} * u_k_t
#
# (terms F_p * dp/dt vanish because dp/dt = 0). This is eq. (2b)/(20b) of the draft written in
# components: X_x * xdot is a Jacobian MATRIX times a vector, T_x . xdot a dot product.
#
# FINITE system, unknowns T, X_i, P_k, U_k (names as in the rest of the repo: X1, X1t, X1x2,
# X1u, T, Tt, Tx1, Tu, P1, P1t, P1x2, U, u_t):
#     states     : f_i(T, X, U, P) * D(T) - D(X_i) = 0      (D(T) = 1 when T = t)
#     parameters : D(P_k) = 0
#     outputs    : h_l(X, u, P) - h_l(x, u, p) = 0
#
# INFINITESIMAL system, V = tau d_t + xi.d_x + zeta.d_p + eta.d_u (unknown names: tau, xi_x1,
# zeta_p1, eta_u and derivatives tau_t, tau_x1, xi_x1_t, xi_x1_x2, xi_x1_u, zeta_p1_x2, ...):
#     states     : D(xi_i) - f_i D(tau) - V(f_i) = 0
#     parameters : D(zeta_k) = 0
#     outputs    : V(h_l) = 0
# with V(g) = tau g_t + sum_j xi_j g_{x_j} + sum_k zeta_k g_{p_k} + sum_k eta_k g_{u_k}.
#
# Options (same for both systems)
#     time_transform   : T (or tau) is an unknown instead of T = t (tau = 0)
#     input_dependence : the unknowns may depend on the inputs (adds F_u * u_t terms)
#     transform_params : parameters are transformed (identifiability); false = observability
#     transform_inputs : inputs are transformed, U(t,x,u) (general transformation, draft Sect. 2)
#     include_output   : add the output condition (false = symmetries of the state eq. only)
#
# Splitting: always w.r.t. u_t; w.r.t. powers of u ONLY if input_dependence = false.
# For rational models, clear denominators before splitting (e.g. numer(normal(.)) in Maple).
#
# Cross-check in Python: scripts/reference_detsys.py (same equations, same names).
# Self-test in Julia:    scripts/TestFiniteDetSys.jl
#__________________________________________________________________________________________

using Symbolics
using SymbolicUtils   # `expand` is used unqualified, as in the rest of the repo

_mkvar(name::AbstractString) = Symbolics.variable(Symbol(name))
_num(x) = x isa Num ? x : Num(x)
_der(g, v) = _num(Symbolics.derivative(_num(g), v))

# Name of the transformed object, as in the rest of the repo: x1 -> X1, k12 -> K12, S -> S_T
_upname(s::AbstractString) = s == uppercase(s) ? s * "_T" : uppercase(s)

# Replace every symbol of a parsed expression by its symbolic variable (no global eval needed)
_replaceSymbols(ex::Symbol, d::Dict{Symbol,Num}) = get(d, ex, ex)
_replaceSymbols(ex::Expr, d::Dict{Symbol,Num}) = Expr(ex.head, [_replaceSymbols(a, d) for a in ex.args]...)
_replaceSymbols(ex, d::Dict{Symbol,Num}) = ex
_toSymbolic(str::AbstractString, d::Dict{Symbol,Num}) = _num(eval(_replaceSymbols(Meta.parse(str), d)))

_iszeroSym(e) = (v = Symbolics.value(expand(_num(e))); v isa Number && iszero(v))

# Reads a model with fields estados, nSalidas, parametros, entradas, ecuaciones
function _parseModel(Model)
    sx  = String.(Model.estados)
    spn = String.(Model.parametros)
    su  = String.(Model.entradas)
    nEq  = length(Model.ecuaciones)
    nOut = Model.nSalidas

    x  = Num[_mkvar(s) for s in sx]
    p  = Num[_mkvar(s) for s in spn]
    u  = Num[_mkvar(s) for s in su]
    ut = Num[_mkvar(s * "_t") for s in su]
    tt = _mkvar("t")

    d = Dict{Symbol,Num}()
    for (s, v) in zip(vcat(sx, spn, su), vcat(x, p, u))
        d[Symbol(s)] = v
    end
    d[:t] = tt
    fx = Num[_toSymbolic(Model.ecuaciones[i], d) for i in 1:(nEq - nOut)]
    hx = Num[_toSymbolic(Model.ecuaciones[i], d) for i in (nEq - nOut + 1):nEq]
    length(fx) == length(sx) || error("The number of state equations ($(length(fx))) differs from the number of states ($(length(sx)))")

    return (sx = sx, spn = spn, su = su, x = x, p = p, u = u, ut = ut, t = tt, fx = fx, hx = hx)
end

"""
    finiteDeterminingSystem(Model; time_transform=false, input_dependence=false,
                            transform_params=true, transform_inputs=false, include_output=true)

Returns `(eqs, syms)`: the finite determining equations (Vector{Num}) and the variables used.
"""
function finiteDeterminingSystem(Model; time_transform::Bool = false,
                                 input_dependence::Bool = false,
                                 transform_params::Bool = true,
                                 transform_inputs::Bool = false,
                                 include_output::Bool = true)
    m = _parseModel(Model)
    sx, spn, su, fx, hx = m.sx, m.spn, m.su, m.fx, m.hx

    Xn = [_upname(s) for s in sx]
    Pn = [_upname(s) for s in spn]
    X  = Num[_mkvar(n) for n in Xn]
    P  = transform_params ? Num[_mkvar(n) for n in Pn] : m.p

    subsXP = Dict{Num,Num}()
    for (a, b) in zip(m.x, X)
        subsXP[a] = b
    end
    if transform_params
        for (a, b) in zip(m.p, P)
            subsXP[a] = b
        end
    end
    if transform_inputs
        for (a, s) in zip(m.u, su)
            subsXP[a] = _mkvar(_upname(s))
        end
    end
    if time_transform
        subsXP[m.t] = _mkvar("T")
    end
    fX = Num[_num(substitute(e, subsXP)) for e in fx]
    hX = Num[_num(substitute(e, subsXP)) for e in hx]

    # Total derivative of the unknown function called F: sum over ALL states (full Jacobian)
    function D(F::String)
        expr = _mkvar(F * "t")
        for (j, s) in enumerate(sx)
            expr += _mkvar(F * s) * fx[j]
        end
        if input_dependence
            for (k, s) in enumerate(su)
                expr += _mkvar(F * s) * m.ut[k]
            end
        end
        return expr
    end

    DT = time_transform ? D("T") : Num(1)

    eqs = Num[]
    for i in eachindex(sx)
        push!(eqs, expand(fX[i] * DT - D(Xn[i])))
    end
    if transform_params
        for n in Pn
            push!(eqs, expand(D(n)))
        end
    end
    if include_output
        for l in eachindex(hx)
            push!(eqs, expand(hX[l] - hx[l]))
        end
    end

    syms = (x = m.x, p = m.p, u = m.u, ut = m.ut, X = X, P = P, t = m.t)
    return eqs, syms
end

"""
    infinitesimalDeterminingSystem(Model; time_transform=false, input_dependence=false,
                                   transform_params=true, transform_inputs=false, include_output=true)

Linear determining system for V = tau d_t + xi.d_x + zeta.d_p + eta.d_u. Returns `(eqs, syms)`.
"""
function infinitesimalDeterminingSystem(Model; time_transform::Bool = false,
                                        input_dependence::Bool = false,
                                        transform_params::Bool = true,
                                        transform_inputs::Bool = false,
                                        include_output::Bool = true)
    m = _parseModel(Model)
    sx, spn, su, fx, hx = m.sx, m.spn, m.su, m.fx, m.hx

    function D(F::String)
        expr = _mkvar(F * "_t")
        for (j, s) in enumerate(sx)
            expr += _mkvar(F * "_" * s) * fx[j]
        end
        if input_dependence
            for (k, s) in enumerate(su)
                expr += _mkvar(F * "_" * s) * m.ut[k]
            end
        end
        return expr
    end

    tau  = time_transform ? _mkvar("tau") : Num(0)
    xi   = Num[_mkvar("xi_" * s) for s in sx]
    zeta = transform_params ? Num[_mkvar("zeta_" * s) for s in spn] : Num[Num(0) for s in spn]
    eta  = transform_inputs ? Num[_mkvar("eta_" * s) for s in su] : Num[Num(0) for s in su]

    # Action of V on a function g(t, x, p, u)
    function V(g::Num)
        r = tau * _der(g, m.t)
        for (a, v) in zip(xi, m.x)
            r += a * _der(g, v)
        end
        for (a, v) in zip(zeta, m.p)
            r += a * _der(g, v)
        end
        for (a, v) in zip(eta, m.u)
            r += a * _der(g, v)
        end
        return r
    end

    DT = time_transform ? D("tau") : Num(0)

    eqs = Num[]
    for (i, s) in enumerate(sx)
        push!(eqs, expand(D("xi_" * s) - fx[i] * DT - V(fx[i])))
    end
    if transform_params
        for s in spn
            push!(eqs, expand(D("zeta_" * s)))
        end
    end
    if include_output
        for hl in hx
            push!(eqs, expand(V(hl)))
        end
    end

    syms = (x = m.x, p = m.p, u = m.u, ut = m.ut, t = m.t)
    return eqs, syms
end

# Coefficients of a polynomial expression w.r.t. one variable (up to the constant factors k!)
function _splitVar(e::Num, v::Num; maxdeg::Int = 30)
    coeffs = Num[]
    dk = e
    for k in 0:maxdeg
        _iszeroSym(dk) && break
        c = expand(_num(substitute(dk, Dict(v => 0))))
        _iszeroSym(c) || push!(coeffs, c)
        dk = expand(_der(dk, v))
    end
    return coeffs
end

"""
    splitDeterminingSystem(eqs, syms; input_dependence=false)

Coefficients that must vanish: split w.r.t. u_t always, and w.r.t. powers of u only when the
unknowns do not depend on u.
"""
function splitDeterminingSystem(eqs::Vector{Num}, syms; input_dependence::Bool = false)
    gens = input_dependence ? syms.ut : vcat(syms.ut, syms.u)
    out = Num[]
    for e in eqs
        pieces = Num[e]
        for g in gens
            pieces = reduce(vcat, [_splitVar(q, g) for q in pieces]; init = Num[])
        end
        append!(out, filter(q -> !_iszeroSym(q), pieces))
    end
    return out
end

function _writeLines(path::AbstractString, v)
    open(path, "w") do io
        for e in v
            println(io, string(e))
        end
    end
end

"""
    runDeterminingSystem(Model, name, tag; infinitesimal=false, kwargs...)

Builds, splits and writes the determining system to the current folder:
    [infinitesimal_]equations_<name>_<tag>.txt     (one equation per line)
    [infinitesimal_]coefficients_<name>_<tag>.txt  (one coefficient per line)
`kwargs` are the options of finiteDeterminingSystem / infinitesimalDeterminingSystem.
"""
function runDeterminingSystem(Model, name::AbstractString, tag::AbstractString;
                              infinitesimal::Bool = false, kwargs...)
    builder = infinitesimal ? infinitesimalDeterminingSystem : finiteDeterminingSystem
    eqs, syms = builder(Model; kwargs...)
    input_dependence = get(kwargs, :input_dependence, false)
    coeffs = splitDeterminingSystem(eqs, syms; input_dependence = input_dependence)

    prefix = infinitesimal ? "infinitesimal_" : ""
    fileEq = "$(prefix)equations_$(name)_$(tag).txt"
    fileCo = "$(prefix)coefficients_$(name)_$(tag).txt"
    _writeLines(joinpath(pwd(), fileEq), eqs)
    _writeLines(joinpath(pwd(), fileCo), coeffs)
    println((infinitesimal ? "Infinitesimal" : "Finite"), " determining system ($(tag)) for $(name): ",
            "$(length(eqs)) equations, $(length(coeffs)) coefficients after splitting.")
    println("Written to $(fileEq) and $(fileCo) in $(pwd())")
    return eqs, coeffs
end

# Kept for backwards compatibility with the first version of this file
function runFiniteDeterminingSystem(Model, name::AbstractString; time_transform::Bool = false,
                                    input_dependence::Bool = false, transform_params::Bool = true)
    tag = (transform_params ? "SI" : "Obs") * (time_transform ? "_timeT" : "") * (input_dependence ? "_udep" : "")
    return runDeterminingSystem(Model, name, tag; time_transform = time_transform,
                                input_dependence = input_dependence, transform_params = transform_params)
end

"""
    residualOf(eqs, syms, transformation::Dict{String,<:Any})

FINITE system: plugs an explicit transformation, e.g. Dict("X2" => x2 + a*x1, "P1" => p1 + a),
into the equations using its true derivatives. All zero iff it is a symmetry.
List T (if used), all X_i, all P_k and U_k (if used).
"""
function residualOf(eqs::Vector{Num}, syms, transformation::Dict{String,<:Any})
    vars = vcat(syms.x, syms.u)
    subsd = Dict{Num,Num}()
    for (name, F0) in transformation
        F = _num(F0)
        subsd[_mkvar(name)] = F
        subsd[_mkvar(name * "t")] = _der(F, syms.t)
        for v in vars
            subsd[_mkvar(name * string(v))] = _der(F, v)
        end
    end
    return Num[expand(_num(substitute(e, subsd))) for e in eqs]
end

"""
    residualOfInfinitesimal(eqs, syms, generator::Dict{String,<:Any})

INFINITESIMAL system: plugs an explicit generator, e.g. Dict("tau" => 1, "xi_x1" => x1),
into the equations using its true derivatives. All zero iff it is an infinitesimal symmetry.
"""
function residualOfInfinitesimal(eqs::Vector{Num}, syms, generator::Dict{String,<:Any})
    vars = vcat(syms.x, syms.u)
    subsd = Dict{Num,Num}()
    for (name, F0) in generator
        F = _num(F0)
        subsd[_mkvar(name)] = F
        subsd[_mkvar(name * "_t")] = _der(F, syms.t)
        for v in vars
            subsd[_mkvar(name * "_" * string(v))] = _der(F, v)
        end
    end
    return Num[expand(_num(substitute(e, subsd))) for e in eqs]
end
