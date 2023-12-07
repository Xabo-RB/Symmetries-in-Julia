function coefficients(detsys)

    # Select coefficients
    variablesSys = Set()
    for vrs in detsys
        vSys = Symbolics.get_variables(vrs)
        for var in vSys
            push!(variablesSys, var)
        end
    end

    variablesSys = string.(collect(variablesSys))

    varsSymbol = Dict()
    for k in variablesSys
        varsSymbol[k] = sp.symbols(k)
    end

    u_sym = sp.symbols("u")
    varsSymbol["u"] = u_sym

    ecuacionesString = string.(detsys)

    coeffsCollected = []
    for eqq in ecuacionesString

        expr_sympy  = sp.sympify(eqq, locals = varsSymbol)
        expr_sympy1 = sp.expand(expr_sympy)
        expr_collect = sp.collect(expr_sympy1, u_sym)
        push!(coeffsCollected, expr_collect)

    end

    return coeffsCollected
end