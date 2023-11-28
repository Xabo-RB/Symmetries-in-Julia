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

function transformToCoeffs(mod,xd)

    nX = length(mod.states) #number of states
    for i in 1:nX
        # A's: dXi/dt
        str = "@variables A_$i"
        eval(Meta.parse(str))
        # B's: dXi/dxi
        str1 = "@variables B_$i"
        eval(Meta.parse(str1))
        # C's: dT/dxi
        str2 = "@variables C_$i"     
        eval(Meta.parse(str2))



        #DICCCIONARIO
        #Now, the symbolic variable (q) exists, and I store it in the vector st
        push!(St, eval(Meta.parse(q)))
        push!(transSt, eval(Meta.parse(Mayus)))
    end

end

# Esta función va a ser para definir los strings que contengan las derivadas de los estados, "(Differential(t)(X1)"
# y luego convertirlos en símbolos para meterlos en un diccionario y substituirlos.

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
