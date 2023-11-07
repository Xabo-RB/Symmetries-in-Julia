function chainDer(model)
    

    # Crea los operadores diferenciales
    Dt = Differential(t)
    Dx = Differential(x)

    # Calcula la derivada total de X con respecto al tiempo
    dX_dt = Dt(X) + Dx(X) * Dt(x)

    # Simplifica el resultado
    simplified_result = Symbolics.simplify(dX_dt)

    # Muestra el resultado simplificado
    println(simplified_result)

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