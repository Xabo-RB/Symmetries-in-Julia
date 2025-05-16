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

# ----------------- 3º FUNCION ----------------- #
# COMPROBACIÓN, tiene que dar 4
#expr = symbols.G[1] + 4 + symbols.G[2]
#expr_subsDX = funcion3era(expr, symbols)


#(Julia_result, latex_result)  = mainObsCont(symbols)


# ----------------- 4º FUNCION ----------------- #
# whatIs = 1 -> analiza las ecuaciones de estado
# whatIs = 0 -> analiza las ecuaciones de salida
whatIs = 1
epsi_syms = funcion4ta(symbols, whatIs)

# ----------------- 5º FUNCION ----------------- #
condicion2 = funcion5ta(symbols)

H_or_G = 1
f1 = funcion1era(symbols, H_or_G)
f2 = funcion2da(variables)


(xx, yy) = FirstIdentEqn(f1, f2, epsi_syms, variables)
