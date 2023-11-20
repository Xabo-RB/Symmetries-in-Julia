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

Model = userDefined(Number_of_States,states,Number_of_Outputs,Number_of_Parameters,parameters,inputs,ecuaciones)


states = Model.estados
Nstates = Model.nEstados
nOutputs = Model.nSalidas
nParams = Model.nParams
parameters = Model.parametros
inputs = Model.entradas
ecuaciones = Model.ecuaciones


#   - States
st = Num[]
for q in states
    # Meta-programming, this line writes a meta-line code to create the symbolic variable stored in q, that is called as (q)
    str = "@syms $(q)(t)"
    eval(Meta.parse(str))
    # Evaluates the expression to get the newly created symbolic variable and stores it in 'var'.
    var = eval(Meta.parse("$(q)(t)"))
    push!(st, var)
end

#   - Transformed variable of States
ST = Num[]
for q in states
    Mayus = uppercase(q)
    str = "@syms $(Mayus)(t,$(q))"
    ST = eval(Meta.parse(str))
    #var = eval(Meta.parse("$(Mayus)(t,$(q))"))
    #push!(ST, var)
end

# OTRA FORMA ESTA FUNCIONA
# DEVUELVE ESTO:
#==
User
Devuelve esto:

4-element Vector{Num}:
 var"X1(t, x1)"
 var"X2(t, x2)"
 var"X3(t, x3)"
 var"X4(t, x4)"
 ==#
ST = Num[]
for q in states
    Mayus = uppercase(q)
    var_symbol = Symbol(Mayus, "(t, ", q, ")")  # Crear un símbolo para la variable
    @eval begin
        @variables $var_symbol
        push!(ST, $var_symbol)
    end
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
M = ModelSym(st,ST,pr,inU,equations)

# Symbolic derivatives of the states, equation (2b)
xdot = chainDer(M,t)

# The whole equation in the same side
eqn3a = Num[]
for i in eachindex(xdot)
    # xdot (num/den) = TrEquations
    expresion = TrEquations[i] - xdot[i]
    expresion = simplify(expresion)
    push!(eqn3a, expresion)
end

#Substitute de derivatives of the states for the correspondent ode equation
derx =  Num[]
for s in st
    dxt = Differential(t)(s)
    push!(derx,dxt)
end
seqns = equations[1:end-1]
eqn3a2 = Num[]
for i in eachindex(eqn3a)
    treqn = transformVariables(eqn3a[i], derx, seqns) 
    treqn = simplify(treqn)
    push!(eqn3a2,treqn)
end