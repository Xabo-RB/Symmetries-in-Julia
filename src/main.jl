function main(Model,t)
    #_________________________________________________________________________#
    #Convert the model into a symbolic one:

    #HELP:
    # La función Meta.parse en Julia toma una cadena de texto que representa una expresión de código Julia 
    # y la convierte en un objeto de tipo Expr (expresión). Este objeto Expr puede ser luego evaluado con la
    # función eval para ejecutar el código que representa.

    #@variables: Se utiliza para crear variables simbólicas simples que no son funciones de otras variables. Por ejemplo, @variables x y z creará tres variables simbólicas.
    #@syms: Se utiliza para crear variables simbólicas que son funciones de otras variables. Por ejemplo, @syms x(t) creará una variable simbólica x que es una función del tiempo.
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
        global var
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
        global VAR
        Mayus = uppercase(q)
        str = "@syms $(Mayus)(t)"
        eval(Meta.parse(str))
        VAR = eval(Meta.parse("$(Mayus)(t)"))
        push!(ST, VAR)
    end

    #   - Parameters
    pr = Num[]
    for p in parameters
        #Meta-programming, this line write a meta-line code to create the symbolic variable stored in q
        str = "@variables $(p)"
        #Evaluate the line above
        global eval(Meta.parse(str))
        #Now, the symbolic variable (q) exists, and I store it in the vector st
        push!(pr, eval(Meta.parse(p)))
    end

    #   - Inputs
    inU = Num[]
    for m in inputs
        global inp
        str = "@syms $(m)(t)"
        eval(Meta.parse(str))
        inp = eval(Meta.parse("$(m)(t)"))
        push!(inU, inp)
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

    #coefs = Symbolics.coeff(eqn3a2[1],u)

    #https://symbolicutils.juliasymbolics.org/rewrite/
    #https://symbolics.juliasymbolics.org/dev/manual/expression_manipulation/#SymbolicUtils.simplify

    return eqn3a2

end