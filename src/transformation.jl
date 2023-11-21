function transformation(Model,t)

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

    #   - Equations: equations (ode expression with the variables as type Num), TrEquations (the same ode 
    #                ode expression but the states are the transformed states ~x or X)
    equations = Num[]
    TrEquations = Num[]
    for i in eachindex(Model.ecuaciones)
        str = Meta.parse(Model.ecuaciones[i])
        eqn1 = eval(str)
        push!(equations, eqn1)

        transf_eqn = transformVariables(equations[i], St, transSt) 
        push!(TrEquations, transf_eqn)
    end
    #To pass variables to the Model Struct
    M = ModelSym(St,transSt,pr,inU,equations)
    # Symbolic derivatives of the states, equation (2b)
    xdot = chainDer(M,t)

    return equations, TrEquations, xdot

end
