#__________________________________________________________________________________________
#__________________________________________________________________________________________

# --------------------- Method for Structural Identifiability ---------------------
# This script is to obtain the coefficients of the determinig system corresponding to equation (...)
# of section 4. I.e. transformations in chain derivatives (20b, 20c).
# -----------------------------------------------------------------------------------------------

using DrWatson
using Symbolics
using Latexify
using LaTeXStrings
import SymPy as sp
#using SymPy

@quickactivate "Symmetries in Julia"

include(srcdir("functions.jl"))
#include(srcdir("getDeterminingSystem.jl"))
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
    TransParams::Vector{Num}
    inputs::Vector{Num}
    ode::Vector{Num}
    output::Vector{Num}

end

#_____________________________ User defined _____________________________#

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


CreateModel = userDefined(states,salidas,parameters,inputs,ecuaciones)
Model = userDefined(states,salidas,parameters,inputs,ecuaciones)

#function getDeterminingSystemComplete(Model,t)

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
    prTrans = Num[]
    for p in Model.parametros

        # Parameter without transformation --------------------------------------------
        str = "@variables $(p)"
        eval(Meta.parse(str))
        push!(pr, eval(Meta.parse(p)))
        
        # Parameter transformed --------------------------------------------------------
        mayus = es_mayusculas(p)

        if mayus 
            pp = p * "_T" #T from transformed
            str = "@variables $(pp)"
            eval(Meta.parse(str))
            push!(prTrans, eval(Meta.parse(pp)))
        else
            pp = uppercase(p)
            str = "@variables $(pp)"
            eval(Meta.parse(str))
            push!(prTrans, eval(Meta.parse(pp)))
        end
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

        transf_eqn1 = transformVariables(equations[i], St, transSt) 
        transf_eqn = transformVariables(transf_eqn1, pr, prTrans) 
        push!(TrEquations, transf_eqn)
    end

    equationsY = Num[]
    TrEquationsY = Num[]
    #for i in eachindex(Model.ecuaciones)[end-Model.nSalidas+1:end]
    j = 1
    for i in (length(Model.ecuaciones) - Model.nSalidas + 1):length(Model.ecuaciones)
        str = Meta.parse(Model.ecuaciones[i])
        eqn1 = eval(str)
        push!(equationsY, eqn1)

        transf_eqn1 = transformVariables(equationsY[j], St, transSt) 
        transf_eqn = transformVariables(transf_eqn1, pr, prTrans) 
        push!(TrEquationsY, transf_eqn)
        j += 1
    end


    #To pass variables to the Model Struct
    M = ModelSym(St,transSt,pr,prTrans,inU,equations,equationsY)

    # ---------------------- CHAIN DER STATES --------------------- #
    estado = M.states
    estM = M.TransStates 

    # Creates the differential operators
    Dt = Differential(t)

    dotx = Num[]

    for (i, value) in enumerate(estado)
        # Partial erivative with respect a estado[i]
        Dx = Differential(value)

        # Define the variables T(t,x1(t)) as Tx1, Tx2, ...
        str = "@variables T"
        eval(Meta.parse(str))

        # Calculate the total derivative of X with respect to time. estM = X1, X2, ...
        dX_dt = Dt(estM[i]) + Dx(estM[i]) * Dt(estado[i])

        dotxEle = dX_dt

        push!(dotx, dotxEle)

    end

    xdot = copy(dotx)

    # ---------------------- CHAIN DER PARAMETERS --------------------- #
    pars = M.params
    parsT = M.TransParams 

    Pdot = Num[]
    
    for (i, value) in enumerate(pars)
        todasLasDers = Num[]
        for (j, value1) in enumerate(estado)
            # Almaceno en este vector las derivadas parciales de un parámetro con 
            # respecto a todos los estados
            # Partial derivative with respect a estado[i]
            Dx = Differential(value1)
            derivadaConRespectoEstado = Dx(parsT[i])*Dt(estado[j])
            push!(todasLasDers,derivadaConRespectoEstado)
        end

        # Define the variables T(t,x1(t)) as Tx1, Tx2, ...
        str = "@variables T"
        eval(Meta.parse(str))

        # Calculate the total derivative of X with respect to time. estM = X1, X2, ...
        dTheta_dt = Dt(parsT[i]) + sum(todasLasDers)
        
        dotxEle = dTheta_dt

        push!(Pdot, dotxEle)

    end

    dotP = copy(Pdot)

    function creatingDifferentialComplete(mod)
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

        # derivadas primera coefficients dxi/dt
        xdot1 = []
        for i in eachindex(nombresVarT)
            derivada_str = "Differential(t)($(nombresVar[i]))"
            push!(xdot1, derivada_str)
        end 

        return (As, Bs, xdot1)
    end

    function creatingDifferentialComplete2(mod)
        # Vector with all de variable names, states and Mayusculas States as strings
        nombresVarS = map(string, mod.states)
        nombresVarTP = map(string, mod.TransParams)

        # Y's coefficients dKi/dt
        Ys = []
        for nombre in nombresVarTP
            derivada_str = "Differential(t)($(nombre))"
            push!(Ys, derivada_str)
        end

        # Z's coefficients dKi/dxi
        Zs = []
        for i in eachindex(nombresVarTP)
            for j in eachindex(nombresVarS)
                derivada_str = "Differential($(nombresVarS[j]))($(nombresVarTP[i]))"
                push!(Zs, derivada_str)
            end
        end
        return (Ys, Zs)
    end

    tuplaDerivadas = creatingDifferentialComplete(M)
    tuplaDerivadas2 = creatingDifferentialComplete2(M)

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
    xdot1_str = Num[]
    xdot11 = tuplaDerivadas[3]
    for deriv_str in xdot11
        expr_julia = Meta.parse(deriv_str)
        expr_simbolica = eval(expr_julia)
        push!(xdot1_str, expr_simbolica)
    end
    Ys = Num[]
    Ys1 = tuplaDerivadas2[1]
    for deriv_str in Ys1
        expr_julia = Meta.parse(deriv_str)
        expr_simbolica = eval(expr_julia)
        push!(Ys, expr_simbolica)
    end
    Zs = Num[]
    Zs1 = tuplaDerivadas2[2]
    for deriv_str in Zs1
        expr_julia = Meta.parse(deriv_str)
        expr_simbolica = eval(expr_julia)
        push!(Zs, expr_simbolica)
    end

    function creatingCoeffsForDiffsObs(mod)
        nombresVar = map(string, mod.states)
        nombresVarT = map(string, mod.TransStates)

        #d(States)/dt
        A_dSdt = Num[]
        for names in nombresVarT
            # A's: dXi/dt : Xit : /State/t
            str = "@variables $(names)t"
            eval(Meta.parse(str))
            varsym = eval(Meta.parse("$(names)t"))
            push!(A_dSdt, varsym)
        end

        #d(States)/d(states)
        B_dSds = Num[]
        for i in eachindex(nombresVarT)
            # B's: dSi/dsi : Sisi : /Statei//statei/
            str = "@variables $(nombresVarT[i]nombresVar[i])"
            eval(Meta.parse(str))
            varsym = eval(Meta.parse("$(nombresVarT[i]nombresVar[i])"))
            push!(B_dSds, varsym)
        end

        #d(states)/dt
        D_dsdt = Num[]
        for i in eachindex(nombresVarT)
            # D's: dsi/dt : sit : /statei/t
            str = "@variables $(nombresVar[i])t"
            eval(Meta.parse(str))
            varsym = eval(Meta.parse("$(nombresVar[i])t"))
            push!(D_dsdt, varsym)
        end

        return (A_dSdt, B_dSds, D_dsdt)

    end
    ################################# HASTA AQUÍ ##########################################
    function creatingCoeffsForDiffsParams(mod)
        nombresVarS = map(string, mod.states)
        nombresVarTP = map(string, mod.TransParams)

        #d(Params)/dt
        Y_dKdt = Num[]
        for names in nombresVarTP
            # Y's: dKi/dt : Kit : /Parameter/t
            str = "@variables $(names)t"
            eval(Meta.parse(str))
            varsym = eval(Meta.parse("$(names)t"))
            push!(Y_dKdt, varsym)
        end

        #d(Params)/d(states)
        Z_dKds = Num[]
        for i in eachindex(nombresVarTP)
            # Z's: dKi/dsj : Kisj : /Paramsi//statej/
            for j in eachindex(nombresVarS)
                str = "@variables $(nombresVarTP[i]nombresVarS[j])"
                eval(Meta.parse(str))
                varsym = eval(Meta.parse("$(nombresVarTP[i]nombresVarS[j])"))
                push!(Z_dKds, varsym)
            end
        end

        return (Y_dKdt, Z_dKds)

    end

    coeficientes1 = creatingCoeffsForDiffsObs(M)
    coeficientes2 = creatingCoeffsForDiffsParams(M)
    #coeficientes = (coeficientes1...,coeficientes2...)
    coeficientes = (coeficientes1,coeficientes2)

    # For substituting I use 'coeficientes' and 'tuplaStringsNums'
    # Substitute the coefficients in the equation xdot.
    tuplaStringsNums = (As, Bs, xdot1_str)
    xdot_transformed = copy(xdot)
    for j in eachindex(xdot_transformed)
        for i in eachindex(tuplaStringsNums)

            substituyoEsto = tuplaStringsNums[i]
            porEsto = coeficientes[i]

            varsym = transformVariables(xdot_transformed[j], substituyoEsto, porEsto) 
            xdot_transformed[j] = varsym
        end
        #push!(xdot_transformed, varsym)
    end

    # A/B = (...) -> A = (...)B -> (...)B - A
    # Firtsly, I need to get A and B from 'xdot_transformed'
    
    #num_str, den_str = getNumerator(xdot_transformed)
    num_str = string.(xdot_transformed)

    num_xdotT = Num[]
    for i in eachindex(xdot_transformed)
        num = eval(Meta.parse(num_str[i]))
        push!(num_xdotT, num)
    end

    #Substitute dxdt por la ecuación diferencial de dicho estado
    finalNum = Num[]
    for i in eachindex(num_xdotT)
        # Differential equations
        substituyoEsto = coeficientes[3]
        #dsi/dt
        porEsto = equations
        varsym = transformVariables(num_xdotT[i], substituyoEsto, porEsto) 
        push!(finalNum, varsym)
    end

    # Now: A/B = (...) -> A = (...)B -> (...)B - A
    finalSol = Num[]
    finalSol1 = Num[]
    for i in eachindex(finalNum)
        new = TrEquations[i] - finalNum[i]
        new1 = expand(new)
        push!(finalSol, new)
        push!(finalSol1, new1)
    end

    for i in eachindex(TrEquationsY)
        solY = equationsY[i] - TrEquationsY[i]
        solY1 = expand(solY)
        push!(finalSol, solY)
        push!(finalSol1, solY1)
    end

#    return finalSol, finalSol1
#end

#determiningSystem, determiningSystemExpanded = getDeterminingSystemComplete(CreateModel,t)

coeffs = coefficients(determiningSystem)
for eq in coeffs
    latex_expr = latexify(eq)
    render(latex_expr)
end

#print(coeffs)

convertToMaple(coeffs, name)

