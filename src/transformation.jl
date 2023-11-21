function transformation(Model,t)

    states = Model.estados
    Nstates = Model.nEstados
    nOutputs = Model.nSalidas
    nParams = Model.nParams
    parameters = Model.parametros
    inputs = Model.entradas
    ecuaciones = Model.ecuaciones

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

    return equations, TrEquations

end