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

#==
---------------------- PRUEBA DE QUE LA INTEGRACIÓN EXPLÍCITA DA CORRECTO ------------------------
@variables t 
@variables x(t)
# Define una función simbólica desconocida X que depende de x y t
@variables X(t, x)
# Crea los operadores diferenciales
Dt = Differential(t)
Dx = Differential(x)

# Supongamos que x(t) es una función específica, por ejemplo, x(t) = t^2
x_t_func = t^2

# Supongamos que X(t, x) también es una función específica, por ejemplo, X(t, x) = t * x
X_t_x_func(t, x) = t * x  # Definimos la función X como una función de Julia

# Reemplaza las funciones simbólicas con las funciones específicas en la derivada total
dX_dt_expr = Dt(X_t_x_func(t, x_t_func)) + Dx(X_t_x_func(t, x_t_func)) * Dt(x_t_func)

# Realiza la diferenciación explícita
dX_dt = Symbolics.expand_derivatives(dX_dt_expr)

# Simplifica el resultado
simplified_result = Symbolics.simplify(dX_dt)

# Muestra el resultado simplificado
println(simplified_result)

---------------------- PRUEBA DE QUE LA INTEGRACIÓN IMPLÍCITA DA CORRECTO ------------------------
@variables t 
@variables x(t)

# Define una función simbólica desconocida X que depende de x y t
@variables X(t, x)

# Crea los operadores diferenciales
Dt = Differential(t)
Dx = Differential(x)

# Calcula la derivada total de X con respecto al tiempo
dX_dt = Dt(X) + Dx(X) * Dt(x)

# Simplifica el resultado
simplified_result = Symbolics.simplify(dX_dt)

# Muestra el resultado simplificado
println(simplified_result)

# EXPAND_DERIVATIVES
@variables t 
@variables Tx2
Dt = Differential(t)

# Calcula la derivada de Tx1 con respecto a t
dTx1_dt = Dt(Tx2)
Differential(t)(dTx1_dt)

expand_derivatives(dTx1_dt)
==#

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

# This is the same but with parentheses for the added equation
function transformVariables1(expr, vars, varsM)

    #Initialize the dictionary that will contain symbolic expressions
    subs = Dict{Any, Any}()

    for i in eachindex(vars)
        varsM[i] = (varsM[i])
        subs[vars[i]] = varsM[i]
    end

    #Substitute in the equations:
    newExpr = substitute(expr, subs)
    return newExpr

end

function transformToCoeffs(mod,xd)

    nX = length(mod.St) #number of states
    for i in 1:nX
        str = "@variables A_$i"
        str1 = "@variables B_$i"
        str2 = "@variables C_$i"
    end

end



end