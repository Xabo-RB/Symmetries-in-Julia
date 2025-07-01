function coefficients(detsys)

    # Initialize a set to store unique variables
    variablesSys = Set()

    # Iterate over each equation in the system 'detsys' (determiningSystem)
    # Get the variables of the current equatio
    # Add each variable to the system's variable set
    for vrs in detsys
        vSys = Symbolics.get_variables(vrs)
        for var in vSys
            push!(variablesSys, var)
        end
    end

    # Convert the set of variables into a list and then to strings
    variablesSys = string.(collect(variablesSys))

    # Initialize a dictionary to map variable names to Sympy symbols
    varsSymbol = Dict()
    for k in variablesSys
        varsSymbol[k] = sp.symbols(k)
    end

    # Create a Sympy symbol for 'u' and add it to the dictionary
    u_sym = sp.symbols("u")
    varsSymbol["u"] = u_sym

    # Convert each equation in the system to a string
    ecuacionesString = string.(detsys)

    
    coeffsCollected = []
    # Convert the equation from string to a Sympy expression
    # Expand the expression for simplification
    # Collect coefficients of 'u_sym' in the expression
    # Add the collected expression to the list of coefficients
    for eqq in ecuacionesString

        if THIS_SCRIPT == "Run.jl"
            expr_sympy  = sp.sympify(eqq, locals = Dict(k => v.o for (k, v) in varsSymbol))
        elseif THIS_SCRIPT == "RunX.jl"
            expr_sympy  = sp.sympify(eqq, locals = Dict(k => v for (k, v) in varsSymbol))
        else
            # Just in case, when running from the terminal, this variable comes up empty
            expr_sympy  = sp.sympify(eqq, locals = Dict(k => v.o for (k, v) in varsSymbol))
        end

        expr_sympy1 = sp.expand(expr_sympy)
        expr_collect = sp.collect(expr_sympy1, u_sym)
        push!(coeffsCollected, expr_collect)

    end

    return coeffsCollected
end