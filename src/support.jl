function chainDer(model,t)
    
    eqns = model.states

    # Crea los operadores diferenciales
    Dt = Differential(t)
    dX = Num[]
    dT = Num[]
    dotx = Num[]

    for i in eachindex(eqns)
        Dx = Differential(eqns[i])
        @variables X(t, eqns[i])
        @variables T(t, eqns[i])

        dT_dt = Dt(T) + Dx(T) * Dt(eqns[i])

        # Calcula la derivada total de X con respecto al tiempo
        dX_dt = Dt(X) + Dx(X) * Dt(eqns[i])

        dotxEle = dX_dt/dT_dt

        push!(dX, dX_dt)
        push!(dT, dT_dt)
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
==#

function transformVariables(expr::SymbolicUtils.Symbolic, vars::Vector{<:SymbolicUtils.Symbolic},t)
    #Estoy SOLICITANDO que 'expr' sea una variable o expresión  simbólica. 
    #'vars' tiene que ser un vector que contenga variab o exprs simbólicas, subtipos que hereden de Symbolics
    #eso es lo que signicia <:
    #subs = Dict(v => Symbolics.Variable(Symbol(uppercase(string(v)))) for v in vars)

    #Inicializo el diccionario, que va a contener expresiones simbólicas
    subs = Dict{SymbolicUtils.Symbolic, SymbolicUtils.Symbolic}()

    for v in vars
        #  ExprSymbolic to String -> Uppercase -> to Symbol -> Variable symbolic with the symbol
        upper = uppercase(string(v))
        upperSymb = Symbol(upper)
        transVar = Symbolics.Variable(upperSymb)(t)
        
        # Add to the dictionary. Variable 'v' will be associated to the uppercase variable 'transVar'
        subs[v] = transVar
    end

    #Substitute in the equations:
    newExpr = substitute(expr, subs)
    return newExpr

end