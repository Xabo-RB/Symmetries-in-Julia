function FunctionForReading(CreateModel)

    # 1) Tus datos de Model.jl
    stringEstados    = CreateModel.estados
    stringParametros = CreateModel.parametros
    stringEntradas   = CreateModel.entradas
    stringEcuaciones = CreateModel.ecuaciones[1:4]

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

    # 4) Parseo y evalúo cada ecuación (ya usan exactamente esos x1,x2,…):
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

    return symbolic_variables(state_syms, param_syms, input_syms, Dstate_syms, symbolic_expressions, g)
end

function funcion1era(variables)
    
    # Creo el vector que contiene las variables simbólicas de Epsilon, una por cada estado epsi_i
    N = length(variables.S)
    names = [ "epsi$i" for i in 1:N ]   # ["z1","z2",…]
    decl = "@variables " * join(names,   " ")
    eval(Meta.parse(decl))
    epsi_syms = Num[]
    for p in names
        simb = Symbol(p)
        obj  = eval(simb)
        push!(epsi_syms, obj)
    end

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

    #return epsi_syms, psiJ, Jg
    return psiJ
end
