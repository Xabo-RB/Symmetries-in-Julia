using DrWatson
using Symbolics
using Latexify
using LaTeXStrings
#using SymPy

@quickactivate "Julia"
include(srcdir("support.jl"))
include(srcdir("main.jl"))
include(srcdir("getNumerator.jl"))

struct userDefined

    nEstados::Int
    estados::Vector{String}
    nSalidas::Int
    nParams::Int
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

Number_of_States = 4
states = ["x1", "x2", "x3", "x4"]

Number_of_Outputs = 1
Number_of_Parameters = 7
parameters = ["k01","k12","k21","k13","k31","k14","k41"]

inputs = ["u"]

ecuaciones = [
    "- (-(k21+k31+k41+k01)*x1(t) + k12*x2(t) + k13*x3(t) + k14*x4(t) + u(t))",
    "k21*x1(t) - k12*x2(t)",
    "k31*x1(t) - k13*x3(t)",
    "k41*x1(t) - k14*x4(t)",
    "x1(t)"
]
#_________________________________________________________________________#

CreateModel = userDefined(Number_of_States,states,Number_of_Outputs,Number_of_Parameters,parameters,inputs,ecuaciones)

#==
@variables t x y
num_expr = x^2 + y + sin(t)

# Función para convertir variables en una expresión Num a símbolos
function convert_num_to_symbol(expr)
    if expr isa SymbolicUtils.Symbolic
        return Symbol(expr)
    elseif expr isa Number
        return expr
    else
        return map(convert_num_to_symbol, expr.args)
    end
end

# Convertir la expresión Num
symbol_expr = convert_num_to_symbol(num_expr)
==#
# Call to the Main function of the algorithm. Right now, its return the equation 3a of the overleaf paper
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