function main(Model,t)

    states = Model.estados
    Nstates = Model.nEstados
    nOutputs = Model.nSalidas
    nParams = Model.nParams
    parameters = Model.parametros
    inputs = Model.entradas
    ecuaciones = Model.ecuaciones

    #   - States
    St = Symbol[]
    for q in Model.estados
        var = Symbol(q)
        Mayus = uppercase(q)
        var1 = Symbol(Mayus)
        push!(St, var)
        push!(transSt, var1)
    end

    #   - Parameters
    pr = Symbol[]
    for p in parameters
        var = Symbol(p)
        push!(pr, var)
    end

    #   - Inputs
    inU = Symbol[]
    for m in inputs
        var = Symbol(m)
        push!(inU, var)
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





end
