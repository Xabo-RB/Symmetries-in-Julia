using DrWatson
using Symbolics

@quickactivate "Julia"
include(srcdir("support.jl"))

struct Model

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
#Convert the model into a symbolic one:

#HELP:
# La función Meta.parse en Julia toma una cadena de texto que representa una expresión de código Julia 
# y la convierte en un objeto de tipo Expr (expresión). Este objeto Expr puede ser luego evaluado con la
# función eval para ejecutar el código que representa.

#@variables: Se utiliza para crear variables simbólicas simples que no son funciones de otras variables. Por ejemplo, @variables x y z creará tres variables simbólicas.
#@syms: Se utiliza para crear variables simbólicas que son funciones de otras variables. Por ejemplo, @syms x(t) creará una variable simbólica x que es una función del tiempo.

#   - States
st = Num[]
for q in states
    # Meta-programming, this line writes a meta-line code to create the symbolic variable stored in q, that is called as (q)
    str = "@syms $(q)(t)"
    eval(Meta.parse(str))
    # Evalúa la expresión para obtener la variable simbólica recién creada y la almacena en 'var'
    var = eval(Meta.parse("$(q)(t)"))
    push!(st, var)
end

#   - Transformed variable of States
ST = Num[]
for q in states
    Mayus = uppercase(q)
    str = "@syms $(Mayus)(t)"
    eval(Meta.parse(str))
    var = eval(Meta.parse("$(Mayus)(t)"))
    push!(ST, var)
end

#   - Parameters
pr = Num[]
for p in parameters
    #Meta-programming, this line write a meta-line code to create the symbolic variable stored in q
    str = "@variables $(p)"
    #Evaluate the line above
    eval(Meta.parse(str))
    #Now, the symbolic variable (q) exists, and I store it in the vector st
    push!(pr, eval(Meta.parse(p)))
end

#   - Inputs
inU = Num[]
for m in inputs
    str = "@syms $(m)(t)"
    eval(Meta.parse(str))
    var = eval(Meta.parse("$(m)(t)"))
    push!(inU, var)
end

#   - Equations
equations = Num[]
TrEquations = Num[]
for i in eachindex(ecuaciones)
    str = Meta.parse(ecuaciones[i])
    eqn1 = eval(str)
    push!(equations, eqn1)

    transf_eqn = transformVariables(equations[i], st, ST) 
    push!(TrEquations, transf_eqn)
end

#To pass variables to the Model Struct
M = Model(st,ST,pr,inU,equations)

# Symbolic derivatives of the states, equation (2b)
xdot = chainDer(M,t)

eqn3a = Num[]
for i in eachindex(xdot)
    expresion = TrEquations[i] - xdot[i]
    push!(eqn3a, expresion)
end

println(eqn3a)
println(eqn3a[1])
