using DrWatson
using Symbolics
using Latexify
using LaTeXStrings
import SymPy as sp
#using SymPy

@quickactivate "Symmetries in Julia"

include(srcdir("functions.jl"))
include(srcdir("getDeterminingSystem.jl"))
include(srcdir("coefficients.jl"))
include(srcdir("convertToMaple.jl"))
include("Observability.jl")
include("GeneralTransformation.jl")
include("StructuralIdentifiability.jl")



struct userDefined

    estados::Vector{String}
    nSalidas::Int
    parametros::Vector{String}
    entradas::Vector{String}
    ecuaciones::Vector{String}

end
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




#_____________________________ User defined _____________________________#
# ________________________ Example 4.3 SEIR __________________________ NOT YET WORKING
name = "Example_4_3_SEIR"

@variables t

states = ["S", "E", "I", "R", "Q"]

salidas = 1

parameters = ["beta","v","psi","gamma"]

inputs = []

ecuaciones = [
    "-beta*S*I",
    "beta*S*I - v*E",
    "v*E - psi*I -(1-psi)*gamma*I",
    "gamma*Q +(1-psi)*gamma*I",
    "-gamma*Q + psi*I",
    "Q"
]

#_________________________________________________________________________#

# ________________________Bilirubin2__________________________
name = "Bilirubin2"

@variables t

states = ["x1", "x2", "x3", "x4"]

salidas = 1

parameters = ["k01","k12","k21","k13","k31","k14","k41"]

inputs = ["u"]

ecuaciones = [
    "- (-(k21+k31+k41+k01)*x1 + k12*x2 + k13*x3 + k14*x4 + u)",
    "k21*x1 - k12*x2",
    "k31*x1 - k13*x3",
    "k41*x1 - k14*x4",
    "x1"
]

# ________________________LLW1987__________________________
name = "LLW1987"

@variables t

states = ["x1", "x2", "x3"]

salidas = 1

parameters = ["theta1","theta2","theta3","theta4"]

inputs = ["u"]

ecuaciones = [
    "-theta1*x1 + theta2*u",
    "-theta3*x2 + theta4*u",
    "-theta1*x3 - theta3*x3 + theta4*x1*u + theta2*x2*u",
    "x3"
]

#_________________________________________________________________________#

# Which type of transformation do you want to use?

option = 1

#_________________________________________________________________________#
CreateModel = userDefined(states,salidas,parameters,inputs,ecuaciones)

if option == 1
    # Call to the Main function of the algorithm. Right now, its return the equation 3a of the overleaf paper
    determiningSystem, determiningSystemExpanded = getDeterminingSystem(CreateModel,t)
    coeffs = coefficients(determiningSystem)
    for eq in coeffs
        latex_expr = latexify(eq)
        render(latex_expr)
    end
    #print(coeffs)
    convertToMaple(coeffs, name)
elseif option == 2
    
    Observability(CreateModel, name)

elseif option == 3

    GeneralTransformation(CreateModel, name)

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

