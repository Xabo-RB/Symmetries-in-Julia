using DrWatson
using Symbolics
using Latexify
using LaTeXStrings
import SymPy as sp
#using SymPy

@quickactivate "Symmetries in Julia"


#_________________________________________________________________________#
#_________________________________________________________________________#
#_________________________________________________________________________#



# Which type of transformation do you want to use?

#==
1. Reid transformation (option = 1)
2. General transformations (option = 2)
3. Transformations for Observability (option = 3)
4. Transformations for Structural identifiability (option = 4)
==#

option = 4



#_________________________________________________________________________#
#_________________________________________________________________________#
#_________________________________________________________________________#

include("Model.jl")
include(srcdir("functions.jl"))
include(srcdir("getDeterminingSystem.jl"))
include(srcdir("coefficients.jl"))
include(srcdir("convertToMaple.jl"))
include(srcdir("Observability.jl"))
include(srcdir("GeneralTransformation.jl"))
include(srcdir("StructuralIdentifiability.jl"))

struct ModelSym
    states::Vector{Num}
    TransStates::Vector{Num}
    params::Vector{Num}
    inputs::Vector{Num}
    ode::Vector{Num}

end
struct ModelSymObs

    states::Vector{Num}
    TransStates::Vector{Num}
    params::Vector{Num}
    inputs::Vector{Num}
    ode::Vector{Num}
    output::Vector{Num}

end
struct ModelSymSI

    states::Vector{Num}
    TransStates::Vector{Num}
    params::Vector{Num}
    TransParams::Vector{Num}
    inputs::Vector{Num}
    ode::Vector{Num}
    output::Vector{Num}

end

if option == 1
    # Call to the Main function of the algorithm. Right now, its return the equation 3a of the overleaf paper
    determiningSystem, determiningSystemExpanded = getDeterminingSystem(CreateModel,t)
    coeffs = coefficients(determiningSystem)
    for eq in coeffs
        latex_expr = latexify(eq)
        render(latex_expr)
    end
    #print(coeffs)
    convertToMaple(coeffs, name, 1)

elseif option == 2

    GeneralTransformation(CreateModel, name)

elseif option == 3
    
    Observability(CreateModel, name)

elseif option == 4

    StructuralIdentifiability(CreateModel, name)

end
# _______________________________________________________________

#==
# _______________________________________________________________
# Tu expresión en forma de cadena
expr_str = "-X2t + Tt*X1*k21 - Tt*X2*k12 + X2x2*k12*x2 - X2x2*k21*x1 - Tx2*X1*k12*k21*x2 + Tx2*X1*(k21^2)*x1 + Tx2*X2*(k12^2)*x2 - Tx2*X2*k12*k21*x1"
expr_str= ecuacionesString[2]
# Convertir la cadena a una expresión de SymPy
expr_sympy = sp.sympify(expr_str)
expr_collect = sp.collect(expr_sympy, u_sym)
x1 = sp.symbols("x1")
expr_collect = sp.collect(expr_sympy, x1)
expr_sympy  = sp.sympify(expr_str, locals = varsSymbol)

# No funciona
expr_str1= ecuacionesString[1]
expr_sympy  = sp.sympify(expr_str1, locals = varsSymbol)
open("expression.txt", "w") do file
    write(file, expr_str1)
end
# Funciona sin expandirlo antes
ecuacionesString1 = string.(determiningSystem)
expr_str2= ecuacionesString1[1]
expr_sympy  = sp.sympify(expr_str2, locals = varsSymbol)
# _______________________________________________________________
==#

