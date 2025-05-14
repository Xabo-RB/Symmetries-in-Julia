using DrWatson
using Symbolics, SymbolicUtils
using Latexify
using LaTeXStrings



@quickactivate "Symmetries in Julia"

include("Model.jl"); 
include(srcdir("functions_conts.jl"))
include(srcdir("convertToMaple.jl"))
include(srcdir("convertToLatex.jl"))


struct symbolic_variables

    S::Vector{Num}
    P::Vector{Num}
    I::Vector{Num}
    DS::Vector{Num}
    EQ::Vector{Num}
    G::Vector{Num}
    Y::Vector{Num}

end

islike(::Num, ::Type{Number}) = true

symbols = FunctionForReading(CreateModel);


# ----------------- 1º FUNCION ----------------- #
# Para comprobar:
#epsi, epsiJg, Jg = funcion1era(symbols)
# 
# H_or_G = 1, with respect to G // H_or_G not 1, with respect to Y
H_or_G = 1
epsiJg = funcion1era(symbols, H_or_G)

# ----------------- 2º FUNCION ----------------- #
# d [xdot_i - f_i]/ d xdot_i
dgdx = funcion2da(symbols)

# ----------------- 3º FUNCION ----------------- #
# COMPROBACIÓN, tiene que dar 4
#expr = symbols.G[1] + 4 + symbols.G[2]
#expr_subsDX = funcion3era(expr, symbols)

# ----------------- 4º FUNCION ----------------- #
# whatIs = 1 -> analiza las ecuaciones de estado
# whatIs = 0 -> analiza las ecuaciones de salida
whatIs = 0
(epsi_syms, psiJ, Jg) = funcion4ta(symbols, whatIs)

(states_Obs, outputs_Obs) = observabilityContinous(symbols, epsiJg, dgdx, epsi_syms)
fullSystemObs = vcat(states_Obs,outputs_Obs)

# Convertir cada Num a su cadena LaTeX
n = length(fullSystemObs)
latex_strings = Vector{String}(undef, n)
latex_custom = Vector{String}(undef, n)
eqs = Vector{Equation}(undef, n)
for i in 1:n
    eqs[i] = Equation(fullSystemObs[i], 0)
    # latexify devuelve un objeto LatexString, lo convertimos a String
    ls = latexify(eqs[i])
    latex_strings[i] = string(ls)
    # raw"\epsilon" inserta literal \epsilon en la cadena
    latex_custom[i] = replace(latex_strings[i], "epsi" => raw"\xi")
    render(LaTeXString(latex_custom[i]))
end

convertToMaple(fullSystemObs, name, 0)
convertToLatex(latex_custom, name, 0)


