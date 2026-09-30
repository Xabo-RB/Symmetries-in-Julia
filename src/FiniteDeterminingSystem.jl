#__________________________________________________________________________________________
# --------------------- FINITE DETERMINING SYSTEM (full chain rule) ---------------------
#
# Builds the finite determining system of the SIO symmetries using the FULL chain rule.
# Total derivative along solutions of the unknown function F (T, X_i or P_k):
#
#     D(F) = F_t + sum_j F_{x_j} * f_j(t,x,u,p) + sum_k F_{u_k} * u_k_t
#
# (the terms F_p * dp/dt vanish because dp/dt = 0). Equations:
#
#     states     : f_i(T, X, u, P) * D(T) - D(X_i) = 0      (D(T) = 1 when T = t)
#     parameters : D(P_k) = 0
#     outputs    : h_l(X, u, P) - h_l(x, u, p) = 0
#
# Unknowns are plain symbols with the same names used in the rest of the repository:
#     X1, X1t, X1x2, X1u, T, Tt, Tx1, Tu, P1, P1t, P1x2, P1u, u_t
#
# Options
#     time_transform   : T = T(t,x,u,p) instead of T = t
#     input_dependence : T, X, P may depend on the inputs (adds F_u * u_t terms)
#     transform_params : parameters are transformed (structural identifiability);
#                        if false, only observability symmetries are sought (P = p)
#
# Splitting: always w.r.t. u_t; w.r.t. powers of u ONLY if input_dependence = false
# (if the unknowns depend on u, u is a coordinate and cannot be split).
# For rational models, clear denominators before splitting (e.g. numer(normal(.)) in Maple).
#
# Cross-check in Python: scripts/reference_detsys.py (same equations, same names).
# Self-test in Julia:    scripts/TestFiniteDetSys.jl
#__________________________________________________________________________________________

using Symbolics
using SymbolicUtils   # `expand` is used unqualified, as in the rest of the repo

_mkvar(name::AbstractString) = Symbolics.variable(Symbol(name))
_num(x) = x isa Num ? x : Num(x)

# Name of the transformed object, as in the rest of the repo: x1 -> X1, k12 -> K12, S -> S_T
_upname(s::AbstractString) = s == uppercase(s) ? s * "_T" : uppercase(s)

# Replace every symbol of a parsed expression by its symbolic variable (no global eval needed)
_replaceSymbols(ex::Symbol, d::Dict{Symbol,Num}) = get(d, ex, ex)
_replaceSymbols(ex::Expr, d::Dict{Symbol,Num}) = Expr(ex.head, [_replaceSymbols(a, d) for a in ex.args]...)
_replaceSymbols(ex, d::Dict{Symbol,Num}) = ex
_toSymbolic(str::AbstractString, d::Dict{Symbol,Num}) = _num(eval(_replaceSymbols(Meta.parse(str), d)))

_iszeroSym(e) = (v = Symbolics.value(expand(_num(e))); v isa Number && iszero(v))

"""
    finiteDeterminingSystem(Model; time_transform=false, input_dependence=false, transform_params=true)

`Model` needs the fields `estados`, `nSalidas`, `parametros`, `entradas`, `ecuaciones`
(the `userDefined` struct of Model.jl, or a NamedTuple with those fields).
Returns `(eqs, syms)`: the equations (Vector{Num}) and the symbolic variables used.
"""
function finiteDeterminingSystem(Model; time_transform::Bool = false,
                                 input_dependence::Bool = false,
                                 transform_params::Bool = true)

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

    # Parse the model strings into symbolic expressions
    d = Dict{Symbol,Num}()
    for (s, v) in zip(vcat(sx, spn, su), vcat(x, p, u))
        d[Symbol(s)] = v
    end
    d[:t] = tt
    fx = Num[_toSymbolic(Model.ecuaciones[i], d) for i in 1:(nEq - nOut)]
    hx = Num[_toSymbolic(Model.ecuaciones[i], d) for i in (nEq - nOut + 1):nEq]
    length(fx) == length(sx) || error("The number of state equations ($(length(fx))) differs from the number of states ($(length(sx)))")

    # Transformed variables
    Xn = [_upname(s) for s in sx]
    Pn = [_upname(s) for s in spn]
    X  = Num[_mkvar(n) for n in Xn]
    P  = transform_params ? Num[_mkvar(n) for n in Pn] : p

    subsXP = Dict{Num,Num}()
    for (a, b) in zip(x, X)
        subsXP[a] = b
    end
    if transform_params
        for (a, b) in zip(p, P)
            subsXP[a] = b
        end
    end
    if time_transform
        subsXP[tt] = _mkvar("T")
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
                expr += _mkvar(F * s) * ut[k]
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
    for l in eachindex(hx)
        push!(eqs, expand(hX[l] - hx[l]))
    end

    syms = (x = x, p = p, u = u, ut = ut, X = X, P = P, t = tt)
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
        dk = expand(_num(Symbolics.derivative(dk, v)))
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
    runFiniteDeterminingSystem(Model, name; time_transform=false, input_dependence=false, transform_params=true)

Builds, splits and writes the determining system to the current folder:
    equations_<tag>.txt     (one equation per line)
    coefficients_<tag>.txt  (one coefficient per line, same format as the Maple reader expects)
"""
function runFiniteDeterminingSystem(Model, name::AbstractString;
                                    time_transform::Bool = false,
                                    input_dependence::Bool = false,
                                    transform_params::Bool = true)
    eqs, syms = finiteDeterminingSystem(Model; time_transform = time_transform,
                                        input_dependence = input_dependence,
                                        transform_params = transform_params)
    coeffs = splitDeterminingSystem(eqs, syms; input_dependence = input_dependence)

    tag = name * (transform_params ? "_SIO" : "_Obs") *
          (time_transform ? "_timeT" : "") * (input_dependence ? "_udep" : "")
    _writeLines(joinpath(pwd(), "equations_$(tag).txt"), eqs)
    _writeLines(joinpath(pwd(), "coefficients_$(tag).txt"), coeffs)
    println("Determining system for $(name): $(length(eqs)) equations, ",
            "$(length(coeffs)) coefficients after splitting.")
    println("Written to equations_$(tag).txt and coefficients_$(tag).txt in $(pwd())")
    return eqs, coeffs
end

"""
    residualOf(eqs, syms, transformation::Dict{String,<:Any})

Plugs an explicit transformation, e.g. Dict("X2" => x2 + a*x1, "P1" => p1 + a, ...), into the
equations using its true derivatives. Returns the residuals (all zero iff it is a symmetry).
Functions not listed are left as unknown symbols, so list T, all X_i and all P_k.
"""
function residualOf(eqs::Vector{Num}, syms, transformation::Dict{String,<:Any})
    vars = vcat(syms.x, syms.u)
    subsd = Dict{Num,Num}()
    for (name, F0) in transformation
        F = _num(F0)
        subsd[_mkvar(name)] = F
        subsd[_mkvar(name * "t")] = _num(Symbolics.derivative(F, syms.t))
        for v in vars
            subsd[_mkvar(name * string(v))] = _num(Symbolics.derivative(F, v))
        end
    end
    return Num[expand(_num(substitute(e, subsd))) for e in eqs]
end
