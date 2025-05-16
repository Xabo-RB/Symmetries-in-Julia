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

(a1, a2, a3) = mainIdentCont(symbols)


