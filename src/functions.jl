# --------------------- CHAINDER ---------------------
# This function is to get the total derivation of the transformed states by the chain rule
# -----------------------------------------------------------------------------------------------

function chainDer(model,t)
    
    # Here I have already defined the states, x1(t), ... and the transformed states X1(t,x1), X2(t,x2), ...
    # not appear defined as X1(t,x1), appears as X1(t) since it is not relevant. They will be treated as parameters
    # in the determining system.
    estado = model.states
    estM = model.TransStates 

    # Creates the differential operators
    Dt = Differential(t)
    dotx = Num[]

    

    for (i, value) in enumerate(estado)
        # Partial erivative with respect a estado[i]
        Dx = Differential(value)

        # Define the variables T(t,x1(t)) as Tx1, Tx2, ...
        str = "@variables T"
        eval(Meta.parse(str))

        dT_dt = Dt(T) + Dx(T) * Dt(estado[i])

        # Calculate the total derivative of X with respect to time. estM = X1, X2, ...
        dX_dt = Dt(estM[i]) + Dx(estM[i]) * Dt(estado[i])

        dotxEle = dX_dt/dT_dt

        push!(dotx, dotxEle)

    end


    return dotx
end

#__________________________________________________________________________________________
#__________________________________________________________________________________________

# --------------------- TRANSFORMVARIABLES ---------------------
# This function is to substitute the variables in 'vars' to the variables in 'varsM'
# -----------------------------------------------------------------------------------------------
function transformVariables(expr, vars, varsM)

    #Initialize the dictionary that will contain symbolic expressions
    subs = Dict{Any, Any}()

    for i in eachindex(vars)
        subs[vars[i]] = varsM[i]
    end

    #Substitute in the equations:
    newExpr = substitute(expr, subs)
    return newExpr

end

#__________________________________________________________________________________________
#__________________________________________________________________________________________

# --------------------- CREATINGCOEFFSFORDIFFS ---------------------
# This function is to create the variable which represent the differential, in the sense of:
# Differential(t)(X1) -> X1t for example. The name of the state or Uppercase State followed by the variable which 
# derives.
# -----------------------------------------------------------------------------------------------
function creatingCoeffsForDiffs(mod)

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

    #dT/d(states)
    C_dTds = Num[]
    for i in eachindex(nombresVarT)
        # C's: dT/dsi : Tsi : T/statei/
        str = "@variables T$(nombresVar[i])"
        eval(Meta.parse(str))
        varsym = eval(Meta.parse("T$(nombresVar[i])"))
        push!(C_dTds, varsym)
    end

    @variables Tt

    return (A_dSdt, B_dSds, C_dTds, Tt)

end

#__________________________________________________________________________________________
#__________________________________________________________________________________________

# --------------------- CREATINGDIFFERENTIAL ---------------------
# Esta función va a ser para definir los strings que contengan las derivadas de los estados, "(Differential(t)(X1)"
# y luego convertirlos en símbolos para meterlos en un diccionario y substituirlos.
# -----------------------------------------------------------------------------------------------
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

    return (As, Bs, Cs, xdot1, derTemporal)
end
