# Self-test of src/FiniteDeterminingSystem.jl (finite and infinitesimal systems).
#
# Expected output (the same numbers come out of: python3 scripts/reference_detsys.py --extra):
#   FINITE, DAISY_EX3
#     swap p4 <-> p7        : all zeros in the three cases (discrete symmetry -> SLING)
#     family (a, g)         : zeros only WITHOUT input; with input [0, -a*u, g*u*(...), 0, ...]
#     time shift T = t + c  : zeros in the time-transform setting (a false positive)
#   FINITE, observability : swap x1 <-> x2 of x1' = p x2, x2' = p x1, y = x1 + x2 -> zeros
#   INFINITESIMAL, DAISY_EX3 : generators d/da, d/dg of the family -> zeros without input;
#                              with input [0, u, 0, ...] and [0, 0, u*(p4 - p7), 0, ...]
#   INFINITESIMAL, Nick (x' = 1 + u x, no output), general transformation:
#     Werner's field (Example 6.4) with eta -> [0]; without eta -> nonzero

using DrWatson
@quickactivate "Symmetries in Julia"
using Symbolics
using SymbolicUtils
include(srcdir("FiniteDeterminingSystem.jl"))

model(states, params, inputs, eqs, nOut) = (estados = states, nSalidas = nOut,
                                            parametros = params, entradas = inputs, ecuaciones = eqs)
daisy(inputs, f1) = model(["x1", "x2", "x3"], ["p1", "p3", "p4", "p6", "p7"], inputs,
                          [f1, "p3*x1 - p4*x2 + x3", "p6*x1 - p7*x3", "x1"], 1)

@variables a g c

# ------------------------------- FINITE -------------------------------
cases = [("with input, T = t", daisy(["u"], "-p1*x1 + x2 + u"), false),
         ("without input, T = t", daisy(String[], "-p1*x1 + x2"), false),
         ("with input, T and u-dependence", daisy(["u"], "-p1*x1 + x2 + u"), true)]

for (label, m, tt) in cases
    eqs, syms = finiteDeterminingSystem(m; time_transform = tt, input_dependence = tt)
    x1, x2, x3 = syms.x
    p1, p3, p4, p6, p7 = syms.p
    t = syms.t

    β  = g * (p4 - p7 + g)
    P4 = p4 + g - a
    family = Dict{String,Any}("X1" => x1, "X2" => x2 + a*x1, "X3" => x3 + β*x1 + g*x2,
                              "P1" => p1 + a, "P4" => P4, "P7" => p7 - g,
                              "P3" => p3 - a*p1 + a*P4 - β,
                              "P6" => p6 - β*p1 + g*p3 + (p7 - g)*β)
    swap = Dict{String,Any}(k => substitute(v, Dict(a => 0, g => p7 - p4)) for (k, v) in family)
    if tt
        family["T"] = t
        swap["T"] = t
    end
    shift = Dict{String,Any}("T" => t + c, "X1" => x1, "X2" => x2, "X3" => x3,
                             "P1" => p1, "P3" => p3, "P4" => p4, "P6" => p6, "P7" => p7)

    println("\n=== FINITE, DAISY_EX3 ", label, ": ", length(eqs), " equations")
    println("  family (a, g) : ", residualOf(eqs, syms, family))
    println("  swap p4<->p7  : ", residualOf(eqs, syms, swap))
    tt && println("  time shift    : ", residualOf(eqs, syms, shift))
end

mobs = model(["x1", "x2"], ["p"], String[], ["p*x2", "p*x1", "x1 + x2"], 1)
eqs, syms = finiteDeterminingSystem(mobs; transform_params = false)
x1, x2 = syms.x
println("\n=== FINITE, observability swap x1<->x2 : ",
        residualOf(eqs, syms, Dict{String,Any}("X1" => x2, "X2" => x1)))

# ---------------------------- INFINITESIMAL ----------------------------
for (label, m) in [("without input", daisy(String[], "-p1*x1 + x2")),
                   ("with input", daisy(["u"], "-p1*x1 + x2 + u"))]
    eqs, syms = infinitesimalDeterminingSystem(m)
    x1, x2, x3 = syms.x
    p1, p3, p4, p6, p7 = syms.p
    gen_a = Dict{String,Any}("xi_x1" => 0, "xi_x2" => x1, "xi_x3" => 0, "zeta_p1" => 1,
                             "zeta_p3" => -p1 + p4, "zeta_p4" => -1, "zeta_p6" => 0, "zeta_p7" => 0)
    gen_g = Dict{String,Any}("xi_x1" => 0, "xi_x2" => 0, "xi_x3" => (p4 - p7)*x1 + x2,
                             "zeta_p1" => 0, "zeta_p3" => -(p4 - p7), "zeta_p4" => 1,
                             "zeta_p6" => -(p4 - p7)*p1 + p3 + p7*(p4 - p7), "zeta_p7" => -1)
    println("\n=== INFINITESIMAL, DAISY_EX3 ", label)
    println("  generator d/da : ", residualOfInfinitesimal(eqs, syms, gen_a))
    println("  generator d/dg : ", residualOfInfinitesimal(eqs, syms, gen_g))
end

mnick = model(["x"], String[], ["u"], ["1 + u*x"], 0)
eqs, syms = infinitesimalDeterminingSystem(mnick; time_transform = true, input_dependence = true,
                                           transform_params = false, transform_inputs = true,
                                           include_output = false)
x = syms.x[1]
u = syms.u[1]
field = Dict{String,Any}("tau" => u*x, "xi_x" => u*x + u^2*x^2/2, "eta_u" => -(u^2 + u^3*x/2))
println("\n=== INFINITESIMAL, Nick, general transformation")
println("  Werner Ex. 6.4 field with eta    : ", residualOfInfinitesimal(eqs, syms, field))
field["eta_u"] = 0
println("  same field without eta (nonzero) : ", residualOfInfinitesimal(eqs, syms, field))
