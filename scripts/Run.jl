using DrWatson
using Symbolics
using Latexify
using LaTeXStrings
#using SymPy

@quickactivate "Julia"
include(srcdir("support.jl"))
include(srcdir("main.jl"))
include(srcdir("getNumerator.jl"))
include(srcdir("transformation.jl"))

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


#_____________________________ User defined _____________________________#
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
#_________________________________________________________________________#

CreateModel = userDefined(states,salidas,parameters,inputs,ecuaciones)

# Call to the Main function of the algorithm. Right now, its return the equation 3a of the overleaf paper
eqn, Treqn, derxT = transformation(CreateModel,t)

equation3apaper = main(CreateModel,t)

Numer, Denom = getNumerator(equation3apaper)

expresion = Meta.parse(Denom[3])
resultado = eval(expresion)

for eq in equation3apaper
    latex_expr = latexify(eq)
    render(latex_expr)
end

# ESTÁ MAL, LAS DERIVADAS DE LAS X MAYÚSCULAS SE CREAN SÓLO COMO X MAYÚSCULA Y NO COMO X1 MAYUSCULA.
# T MAYÚSCULA NO ESTÁ DEFINIDO COMO UNA VARIABLE.

#NOTAS PARA MI:
# ME QUEDA OBTENER LOS COEFICIENTES, ANTES TENGO QUE QUITAR LOS DENOMINADORES PROGRAMANDO CON STRINGS
# Probar obtener los denominadores con Sympy?

