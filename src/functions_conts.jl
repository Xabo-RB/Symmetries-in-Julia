function FunctionForReading(CreateModel)

    # 1) Tus datos de Model.jl
    stringEstados    = CreateModel.estados
    stringParametros = CreateModel.parametros
    stringEntradas   = CreateModel.entradas
    nEq = length(CreateModel.ecuaciones)
    stringEcuaciones = CreateModel.ecuaciones[1:(nEq-CreateModel.nSalidas)]
    stringEcuacionesOut = CreateModel.ecuaciones[(nEq-CreateModel.nSalidas)+1:end]


    # 2) Declarar todas las variables simbólicas a la vez usando el macro @variables y evaluando la cadena generada
    decl = "@variables " *
        join(stringEstados,   " ") * " " *
        join(stringParametros," ") * " " *
        join(stringEntradas,  " ")

    decl_dx = decl * " " * join([ "d" * s for s in stringEstados ], " ")
    eval(Meta.parse(decl_dx))  # Convierte el string en una expresión Julia y la evalúa para declarar las variables simbólicas


    # 3) Ahora reconstruyo mis vectores con esos mismos objetos Num:
    state_syms = Num[]
    for s in stringEstados
        simb = Symbol(s)         # Convertir el string a símbolo Julia (:x1, :x2, etc.)
        obj  = eval(simb)        # Evaluar el símbolo, que ya ha sido definido como variable simbólica
        push!(state_syms, obj)   # Añadir el objeto simbólico al vector
    end
    param_syms = Num[]
    for p in stringParametros
        simb = Symbol(p)
        obj  = eval(simb)
        push!(param_syms, obj)
    end
    input_syms = Num[]
    for u in stringEntradas
        simb = Symbol(u)
        obj  = eval(simb)
        push!(input_syms, obj)
    end

    Dstate_syms = [ eval(Symbol("d"*s))   for s in stringEstados ]

    # 4) Leo el string y evalúo cada ecuación (ya usan exactamente esos x1,x2,…):
    symbolic_expressions = Num[]
    for eq in stringEcuaciones
        parsed_expr = Meta.parse(eq)  # Convertir el string en una expresión Julia (Expr)
        symbolic_eq = eval(parsed_expr)  # Evaluar esa expresión usando las variables simbólicas declaradas
        push!(symbolic_expressions, symbolic_eq)  # Añadir la expresión al vector de expresiones simbólicas
    end

    # 4) gᵢ = dxi – fi 
    g = Vector{typeof(Dstate_syms[1])}()
    for i in eachindex(Dstate_syms, symbolic_expressions)
        push!(g, Dstate_syms[i] - symbolic_expressions[i])
    end

    # 4) Leo el string y evalúo cada ecuación de salida:
    symbolic_expressionsOut = Num[]
    for eq in stringEcuacionesOut
        parsed_expr = Meta.parse(eq)  # Convertir el string en una expresión Julia (Expr)
        symbolic_eq = eval(parsed_expr)  # Evaluar esa expresión usando las variables simbólicas declaradas
        push!(symbolic_expressionsOut, symbolic_eq)  # Añadir la expresión al vector de expresiones simbólicas
    end

    #subsmap = Dict(zip(Dstate_syms, symbolic_expressions))

    return symbolic_variables(state_syms, param_syms, input_syms, Dstate_syms, symbolic_expressions, g, symbolic_expressionsOut)
end

#_________________________________________________________________________#
#_________________________________________________________________________#
#_________________________________________________________________________#

# ---------- EPSI es XI pero al principio me equvoqué de nombre, por eso muchas veces se llaman las 
# ---------- variables EPSI dentro del código

function funcion1era(variables, queDerivo)

    # queDerivo = 1, with respect to G // queDerivo not 1, with respect to Y
    # Creo el vector que contiene las variables simbólicas de Epsilon, una por cada estado epsi_i
    N = length(variables.S)
    names = [ "epsi_$i" for i in 1:N ]   # ["z1","z2",…]
    decl = "@variables " * join(names,   " ")
    eval(Meta.parse(decl))
    epsi_syms = Num[]
    for p in names
        simb = Symbol(p)
        obj  = eval(simb)
        push!(epsi_syms, obj)
    end

    if queDerivo == 1
        # Derivadas de g con respecto a cada estado
        Jg = Symbolics.jacobian(variables.G, variables.S)

        n = size(Jg, 1)
        m = length(epsi_syms)
        psiJ = Vector{Num}(undef, n)
        # Multiplicar cada fila 'i' (derivadas de eqn'i' con respecto x_j de j = 1 a n) por el epsilon 'i'
        # correspondiente al estado 'i'/eqn 'i'
        for i in 1:n
            rest = Vector{Num}(undef, m)
            for j in 1:m
                rest[j] =  epsi_syms[j] * Jg[i, j]
            end
            psiJ[i] = sum(rest)
        end
    else

        # Derivadas de h con respecto a cada estado
        Jg = Symbolics.jacobian(variables.Y, variables.S)

        n = size(Jg, 1)
        m = length(epsi_syms)
        psiJ = Vector{Num}(undef, n)
        # Multiplicar cada fila 'i' (derivadas de eqn'i' con respecto x_j de j = 1 a n) por el epsilon 'i'
        # correspondiente al estado 'i'/eqn 'i'
        for i in 1:n
            rest = Vector{Num}(undef, m)
            for j in 1:m
                rest[j] =  epsi_syms[j] * Jg[i, j]
            end
            psiJ[i] = sum(rest)
        end

    end

    #return epsi_syms, psiJ, Jg
    return psiJ
end

#_________________________________________________________________________#
#_________________________________________________________________________#
#_________________________________________________________________________#

function funcion2da(variables)

    # Derivadas de g con respecto a la derivada de cada estado
    Jg = Symbolics.jacobian(variables.G, variables.DS)
    m = length(variables.DS)
    result = Vector{Num}(undef, m)
    # ** Estoy cogiendo la diagonal, pero debería ser la matriz jacobiana, dado que para cada expresión
    # G se deriva con respecto a cada dx_i, no sólo con respecto al correspondiente **
    for i in 1:m
        result[i] = Jg[i,i]
    end

    return result

end

#_________________________________________________________________________#
#_________________________________________________________________________#
#_________________________________________________________________________#

# ----------------- 3º FUNCION ----------------- #
# COMPROBACIÓN, tiene que dar 4
#expr = symbols.G[1] + 4 + symbols.G[2]
#expr_subsDX = funcion3era(expr, symbols)

#_________________________________________________________________________#
#_________________________________________________________________________#
#_________________________________________________________________________#

function funcion3era(expr, variables)

    # Diccionario de sustitución
    subsmap = Dict{Num,Num}( zip(variables.DS, variables.EQ) )
    # Substituyo
    expr_subst = substitute(expr, subsmap)

    return expr_subst

end

#_________________________________________________________________________#
#_________________________________________________________________________#
#_________________________________________________________________________#

function observabilityContinous(variables, fun1, fun2)

    # CREO Epsilon_x_i
    N = length(variables.S)
    names = [ "epsi_x_$i" for i in 1:N ]   # ["z1","z2",…]
    decl = "@variables " * join(names,   " ")
    eval(Meta.parse(decl))
    epsi_x_syms = Num[]
    for p in names
        simb = Symbol(p)
        obj  = eval(simb)
        push!(epsi_x_syms, obj)
    end

    # CREO Epsilon_i_t
    N = length(variables.S)
    names = [ "epsi_t_$i" for i in 1:N ]   # ["z1","z2",…]
    decl = "@variables " * join(names,   " ")
    eval(Meta.parse(decl))
    epsi_t_syms = Num[]
    for p in names
        simb = Symbol(p)
        obj  = eval(simb)
        push!(epsi_t_syms, obj)
    end

    # Construyo la ecuación 1era de Delta_j
    m = length(fun1)
    eqn1 = Num[]
    for i in 1:m
        obj = fun1[i] + (epsi_t_syms[i] + epsi_x_syms[i]*variables.DS[i])*fun2[i]
        push!(eqn1, obj)
    end
    # Substituyo las derivadas de los estados por su ecuación correspondiente de estado (las odes)
    eqn1subst = Num[]
    for i in 1:m
        obj = funcion3era(eqn1[i], variables)
        push!(eqn1subst, obj)
    end

    H_or_G = 0
    eqn2_obs = funcion1era(variables, H_or_G)
    m = length(eqn2_obs)
    # Substituyo las derivadas de los estados por su ecuación correspondiente de estado (las odes)
    eqn2_obsSubst = Num[]
    for i in 1:m
        obj = funcion3era(eqn2_obs[i], variables)
        push!(eqn2_obsSubst, obj)
    end

    return eqn1subst, eqn2_obsSubst

end

#_________________________________________________________________________#
#_________________________________________________________________________#
#_________________________________________________________________________#

function storageResultsObs(variables)
    
    # ----------------- 1º FUNCION ----------------- #
    # Para comprobar:
    #epsi, epsiJg, Jg = funcion1era(symbols)
    # 
    # H_or_G = 1, with respect to G // H_or_G not 1, with respect to Y
    H_or_G = 1
    epsiJg = funcion1era(variables, H_or_G)

    # ----------------- 2º FUNCION ----------------- #
    # d [xdot_i - f_i]/ d xdot_i
    dgdx = funcion2da(variables)

    return epsiJg, dgdx

end

#_________________________________________________________________________#
#_________________________________________________________________________#
#_________________________________________________________________________#

function mainObsCont(variables)

    # Resultados primeras 2 funciones
    (f1, f2) = storageResultsObs(variables)
    # Función que recopila y construye las ecuaciones de observabilidad
    (states_Obs, outputs_Obs) = observabilityContinous(variables, f1, f2)
    # Concatena las ecuaciones del sistema correspondientes a los estados y a las salidas
    fullSystemObs = vcat(states_Obs,outputs_Obs)

    # Convertir cada Num a su cadena LaTeX
    n = length(fullSystemObs)
    latex_strings = Vector{String}(undef, n)
    latex_custom = Vector{String}(undef, n)
    eqs = Vector{Equation}(undef, n)
    for i in 1:n
        eqs[i] = Equation(fullSystemObs[i], 0)
        # latexify devuelve un objeto LatexString, lo convertimos a String
        ls = latexify(eqs[i])
        latex_strings[i] = string(ls)
        # raw"\epsilon" inserta literal \epsilon en la cadena
        latex_custom[i] = replace(latex_strings[i], "epsi" => raw"\xi")
        render(LaTeXString(latex_custom[i]))
    end

    convertToMaple(fullSystemObs, name, 0)
    convertToLatex(latex_custom, name, 0)

    return fullSystemObs, latex_custom
end

#_________________________________________________________________________#
#_________________________________________________________________________#
#_________________________________________________________________________#

function funcion4ta(variables, whatIs)
    
    # Creo el vector que contiene las variables simbólicas de Zeta, una por cada estado Zeta_i
    N = length(variables.P)
    names = [ "zeta_$i" for i in 1:N ]   # ["z1","z2",…]
    decl = "@variables " * join(names,   " ")
    eval(Meta.parse(decl))
    zeta_syms = Num[]
    for p in names
        simb = Symbol(p)
        obj  = eval(simb)
        push!(zeta_syms, obj)
    end

    if whatIs == 1
        # Derivadas de g con respecto a cada Parámetro
        Jg = Symbolics.jacobian(variables.G, variables.P)

        n = size(Jg, 1)
        m = length(zeta_syms)
        zetaJ = Vector{Num}(undef, n)
        # Multiplicar cada fila 'i' (derivadas de eqn'i' con respecto theta_j de j = 1 a n) por el Zeta 'i'
        # correspondiente al estado 'i'/eqn 'i'
        for i in 1:n
            rest = Vector{Num}(undef, m)
            for j in 1:m
                rest[j] =  zeta_syms[j] * Jg[i, j]
            end
            zetaJ[i] = sum(rest)
        end
    else

        # Derivadas del Output con respecto a cada Parámetro
        Jg = Symbolics.jacobian(variables.Y, variables.P)

        n = size(Jg, 1)
        m = length(zeta_syms)
        zetaJ = Vector{Num}(undef, n)
        # Multiplicar cada fila 'i' (derivadas de eqn'i' con respecto x_j de j = 1 a n) por el Zeta 'i'
        # correspondiente al estado 'i'/eqn 'i'
        for i in 1:n
            rest = Vector{Num}(undef, m)
            for j in 1:m
                rest[j] =  zeta_syms[j] * Jg[i, j]
            end
            zetaJ[i] = sum(rest)
        end

    end

    #return zeta_syms, zetaJ, Jg
    return zetaJ
end

#_________________________________________________________________________#
#_________________________________________________________________________#
#_________________________________________________________________________#

function funcion5ta(variables)
    
    # Creo el vector que contiene las variables simbólicas de Zeta_t, una por cada parametro theta_i
    N = length(variables.P)
    names = [ "zeta_t_$i" for i in 1:N ]   # ["z1","z2",…]
    decl = "@variables " * join(names,   " ")
    eval(Meta.parse(decl))
    zeta_syms = Num[]
    for p in names
        simb = Symbol(p)
        obj  = eval(simb)
        push!(zeta_syms, obj)
    end

    # Creo el vector que contiene las variables simbólicas de Zeta_x, una por cada parametro theta_i
    names = [ "zeta_x_$i" for i in 1:N ]   # ["z1","z2",…]
    decl = "@variables " * join(names,   " ")
    eval(Meta.parse(decl))
    zeta_syms1 = Num[]
    for p in names
        simb = Symbol(p)
        obj  = eval(simb)
        push!(zeta_syms1, obj)
    end

    m = length(variables.EQ)
    eqnfnc5 = Num[]
    for j in 1:m
        obj = sum(zeta_syms) + sum(zeta_syms1)*variables.EQ[j]
        push!(eqnfnc5, obj)
    end
    return eqnfnc5
end

#_________________________________________________________________________#
#_________________________________________________________________________#
#_________________________________________________________________________#

function FirstIdentEqn(f1, f2, f4, variables)

    # Función para construir la primera ecuación del sistema delta_j

    # CREO Epsilon_x_i
    N = length(variables.S)
    names = [ "epsi_x_$i" for i in 1:N ]   # ["z1","z2",…]
    decl = "@variables " * join(names,   " ")
    eval(Meta.parse(decl))
    epsi_x_syms = Num[]
    for p in names
        simb = Symbol(p)
        obj  = eval(simb)
        push!(epsi_x_syms, obj)
    end

    # CREO Epsilon_i_t
    names = [ "epsi_t_$i" for i in 1:N ]   # ["z1","z2",…]
    decl = "@variables " * join(names,   " ")
    eval(Meta.parse(decl))
    epsi_t_syms = Num[]
    for p in names
        simb = Symbol(p)
        obj  = eval(simb)
        push!(epsi_t_syms, obj)
    end

    #== CORRECCIÓN ERROR EN LA EQN PARA S.Id. 
    eqn1_Ident = Num[]
    eqn1_IdentSubst = Num[]
    for i in 1:N
        obj = f1[i] + f4[i] + (epsi_t_syms[i] + (epsi_x_syms[i] - 1)*variables.DS[i])*f2[i]
        push!(eqn1_Ident, obj)
        obj1 = funcion3era(eqn1_Ident[i], variables)
        push!(eqn1_IdentSubst, obj1)
    end
    ==#

    eqn1_Ident = Num[]
    eqn1_IdentSubst = Num[]
    for i in 1:N
        obj = f1[i] + f4[i] + (epsi_t_syms[i] + epsi_x_syms[i]*variables.DS[i])*f2[i]
        push!(eqn1_Ident, obj)
        obj1 = funcion3era(eqn1_Ident[i], variables)
        push!(eqn1_IdentSubst, obj1)
    end

    return eqn1_IdentSubst

end

#_________________________________________________________________________#
#_________________________________________________________________________#
#_________________________________________________________________________#

function mainIdentCont(variables)

    # ----------------- 4º FUNCION ----------------- #
    # Derivada con respecto de los parámetros
    # whatIs = 1 -> analiza las ecuaciones de estado
    # whatIs = 0 -> analiza las ecuaciones de salida
    whatIs = 1
    f4 = funcion4ta(variables, whatIs)

    # ----------------- 5º FUNCION ----------------- #
    # Calcula la segunda ecuación de la simetría: zeta_t + zeta_x * f
    eqn2_simetria = funcion5ta(variables)    

    # Calcula para [g = dotx- f]
    H_or_G = 1
    f1 = funcion1era(variables, H_or_G)
    f2 = funcion2da(variables)
    # Calcula la primera ecuación de la simetría
    eqn1_simetria = FirstIdentEqn(f1, f2, f4, variables)

    # Calcula la 3 ecuación de la simetría
    N = length(variables.Y)
    H_or_G = 0
    f1Y = funcion1era(variables, H_or_G)
    whatIs = 0
    f4Y = funcion4ta(variables, whatIs)
    N = length(f4Y)
    eqn3_simetria = Num[]
    for i = 1:N
        obj = f1Y[i] + f4Y[i]
        push!(eqn3_simetria, obj)
    end

    # Concatena las ecuaciones del sistema correspondientes a los estados y a las salidas
    fullSystemIdent = vcat(eqn1_simetria,eqn2_simetria,eqn3_simetria)

    # Convertir cada Num a su cadena LaTeX
    n = length(fullSystemIdent)
    latex_strings = Vector{String}(undef, n)
    latex_custom = Vector{String}(undef, n)
    eqs = Vector{Equation}(undef, n)
    for i in 1:n
        eqs[i] = Equation(fullSystemIdent[i], 0)
        # latexify devuelve un objeto LatexString, lo convertimos a String
        ls = latexify(eqs[i])
        latex_strings[i] = string(ls)
        # raw"\epsilon" inserta literal \epsilon en la cadena
        latex_custom[i] = replace(latex_strings[i], "epsi" => raw"\xi", "zeta" => raw"\zeta")
        render(LaTeXString(latex_custom[i]))
    end

    convertToMaple(fullSystemIdent, name, 0)
    convertToLatex(latex_custom, name, 0)

    return fullSystemIdent, latex_custom
    #return eqn1_simetria, eqn2_simetria, eqn3_simetria

end