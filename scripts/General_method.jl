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

# ________________________Bilirubin2__________________________
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

Model = userDefined(states,salidas,parameters,inputs,ecuaciones)

#   - States
St = Num[]
transSt = Num[]
for q in Model.estados
    #Meta-programming, this line write a meta-line code to create the symbolic variable stored in q
    Mayus = uppercase(q)
    str = "@variables $(q)"
    str1 = "@variables $(Mayus)"
    #Evaluate the line above
    eval(Meta.parse(str))
    eval(Meta.parse(str1))
    #Now, the symbolic variable (q) exists, and I store it in the vector st
    push!(St, eval(Meta.parse(q)))
    push!(transSt, eval(Meta.parse(Mayus)))
end

#   - Parameters
pr = Num[]
for p in Model.parametros
    str = "@variables $(p)"
    eval(Meta.parse(str))
    push!(pr, eval(Meta.parse(p)))
end

#   - Inputs
inU = Num[]
for m in Model.entradas
    str = "@variables $(m)"
    eval(Meta.parse(str))
    push!(inU, eval(Meta.parse("$(m)")))
end

#   - Equations: equations (ode expression with the variables as type Num), TrEquations (the same ode 
#                ode expression but the states are the transformed states ~x or X)
equations = Num[]
TrEquations = Num[]
for i in eachindex(Model.ecuaciones)[1:end-Model.nSalidas]
    str = Meta.parse(Model.ecuaciones[i])
    eqn1 = eval(str)
    push!(equations, eqn1)

    transf_eqn = transformVariables(equations[i], St, transSt) 
    push!(TrEquations, transf_eqn)
end
#To pass variables to the Model Struct
M = ModelSym(St,transSt,pr,inU,equations)


estado = M.states
estM = M.TransStates 

# Creates the differential operators
Dt = Differential(t)
# --- Hacer esto para varias salidas de control posibles --- #
Du = Differential(inU)
Du = Differential(u)

dotx = Num[]

for (i, value) in enumerate(estado)
    # Partial erivative with respect a estado[i]
    Dx = Differential(value)

    # Define the variables T(t,x1(t)) as Tx1, Tx2, ...
    str = "@variables T"
    eval(Meta.parse(str))

    # Ojo aquí en la u, si hubiera varias variables control habría que cambiarlo
    dT_dt = Dt(T) + Dx(T) * Dt(estado[i]) + Du(T)*Dt(u)


    # Calculate the total derivative of X with respect to time. estM = X1, X2, ...
    dX_dt = Dt(estM[i]) + Dx(estM[i]) * Dt(estado[i]) + Du(estM[i])*Dt(u)

    dotxEle = dX_dt/dT_dt

    push!(dotx, dotxEle)

end


function creatingDifferential(mod)
    # Vector with all de variable names, states and Mayusculas States as strings
    nombresVar = map(string, mod.states)
    nombresVarT = map(string, mod.TransStates)

    # A's coefficients dXi/dt
    As = []
    for nombre in nombresVarT
        derivada_str = "Differential(t)($(nombre))"
        push!(As, derivada_str)
    end

    # B's coefficients dXi/dxi
    Bs = []
    for i in eachindex(nombresVarT)
        derivada_str = "Differential($(nombresVar[i]))($(nombresVarT[i]))"
        push!(Bs, derivada_str)
    end

    # C's coefficients dT/dxi
    Cs = []
    for i in eachindex(nombresVarT)
        derivada_str = "Differential($(nombresVar[i]))(T)"
        push!(Cs, derivada_str)
    end    

    # derivadas primera coefficients dxi/dt
    xdot1 = []
    for i in eachindex(nombresVarT)
        derivada_str = "Differential(t)($(nombresVar[i]))"
        push!(xdot1, derivada_str)
    end 

    derTemporal = "Differential(t)(T)"

    # E's coefficients dXi/du
    Es = []
    for nombre in nombresVarT
        derivada_str = "Differential(u)($(nombre))"
        push!(Es, derivada_str)
    end

    derTemporalU = "Differential(u)(T)"

    udot = "Differential(t)(u)"

    return (As, Bs, Cs, xdot1, derTemporal, Es, derTemporalU, udot)
end

tuplaDerivadas = creatingDifferential(M)

As = Num[]
As1 = tuplaDerivadas[1]
for deriv_str in As1
    expr_julia = Meta.parse(deriv_str)
    expr_simbolica = eval(expr_julia)
    push!(As, expr_simbolica)
end
Bs = Num[]
Bs1 = tuplaDerivadas[2]
for deriv_str in Bs1
    expr_julia = Meta.parse(deriv_str)
    expr_simbolica = eval(expr_julia)
    push!(Bs, expr_simbolica)
end
Cs = Num[]
Cs1 = tuplaDerivadas[3]
for deriv_str in Cs1
    expr_julia = Meta.parse(deriv_str)
    expr_simbolica = eval(expr_julia)
    push!(Cs, expr_simbolica)
end
xdot1_str = Num[]
xdot11 = tuplaDerivadas[4]
for deriv_str in xdot11
    expr_julia = Meta.parse(deriv_str)
    expr_simbolica = eval(expr_julia)
    push!(xdot1_str, expr_simbolica)
end  
derTemporal1 = Num[]
push!(derTemporal1, eval(Meta.parse(tuplaDerivadas[5])))