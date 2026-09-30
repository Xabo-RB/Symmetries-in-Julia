# Self-test of src/FiniteDeterminingSystem.jl on DAISY_EX3.
#
# Expected output:
#   - swap p4 <-> p7          : all zeros in the three cases (discrete symmetry -> SLING)
#   - family (a, g)           : all zeros only WITHOUT input; with input [0, -a*u, g*u*(...), 0, ...]
#   - time shift T = t + c    : all zeros in the time-transform setting (a false positive:
#                               DAISY_EX3 with input is at least locally identifiable)
# The same numbers come out of the Python cross-check: python3 scripts/reference_detsys.py

using DrWatson
@quickactivate "Symmetries in Julia"
using Symbolics
using SymbolicUtils
include(srcdir("FiniteDeterminingSystem.jl"))

daisy(inputs, f1) = (estados = ["x1", "x2", "x3"], nSalidas = 1,
                     parametros = ["p1", "p3", "p4", "p6", "p7"], entradas = inputs,
                     ecuaciones = [f1, "p3*x1 - p4*x2 + x3", "p6*x1 - p7*x3", "x1"])

@variables a g c

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

    println("\n=== DAISY_EX3 ", label, ": ", length(eqs), " equations")
    println("  family (a, g) : ", residualOf(eqs, syms, family))
    println("  swap p4<->p7  : ", residualOf(eqs, syms, swap))
    tt && println("  time shift    : ", residualOf(eqs, syms, shift))
end
