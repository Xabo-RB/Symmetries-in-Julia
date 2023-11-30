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

    # Symbolic derivatives of the states, equation (2b): Xt + Xx dot(x) / Tt + Tx dot(x)
    xdot = chainDer(M,t)

    # ( [As -> dXi/dt], [Bs -> dXi/dxi], [Cs -> dT/dxi], [xdot1 -> dxi/dt], derTemporal )
    # Tupla with the strings representing the derivatives, such as: Differential(t)(X1)
    tuplaDerivadas = creatingDifferential(M)

    # ------------------ ------------------ ------------------ ------------------ ------------------
    # Convert the derivatives in tuplaDerivadas to Num
    As = Num[]
    As1 = tuplaDerivadas[1]
    for deriv_str in As1
        expr_julia = Meta.parse(deriv_str)
        expr_simbolica = eval(expr_julia)
        push!(As, expr_simbolica)
    end
    Bs = Num[]
    Bs1 = tuplaDerivadas[2]
    for deriv_str in Bs1
        expr_julia = Meta.parse(deriv_str)
        expr_simbolica = eval(expr_julia)
        push!(Bs, expr_simbolica)
    end
    Cs = Num[]
    Cs1 = tuplaDerivadas[3]
    for deriv_str in Cs1
        expr_julia = Meta.parse(deriv_str)
        expr_simbolica = eval(expr_julia)
        push!(Cs, expr_simbolica)
    end
    xdot1_str = Num[]
    xdot11 = tuplaDerivadas[4]
    for deriv_str in xdot11
        expr_julia = Meta.parse(deriv_str)
        expr_simbolica = eval(expr_julia)
        push!(xdot1_str, expr_simbolica)
    end  
    derTemporal1 = Num[]
    push!(derTemporal1, eval(Meta.parse(tuplaDerivadas[5])))
    # ------------------ ------------------ ------------------ ------------------ ------------------
    

    # Coefficients for substituting the derivatives, such as Xit = dXi/dt. Its a tupla, with As, Bs, Cs, Ds and dT/dt
    # (A_dSdt, B_dSds, C_dTds, D_dsdt, Tt)
    coeficientes = creatingCoeffsForDiffs(M)
    
    # For substituting I use 'coeficientes' and 'tuplaStringsNums'
    # Substitute the coefficients in the equation xdot.
    tuplaStringsNums = (As,Bs,Cs,xdot1_str,derTemporal1)
    xdot_transformed = copy(xdot)
    for j in eachindex(xdot_transformed)
        for i in eachindex(tuplaStringsNums)

            substituyoEsto = tuplaStringsNums[i]
            porEsto = coeficientes[i]

            varsym = transformVariables(xdot_transformed[j], substituyoEsto, porEsto) 
            xdot_transformed[j] = varsym
        end
        #push!(xdot_transformed, varsym)
    end
    
    # A/B = (...) -> A = (...)B -> (...)B - A
    # Firtsly, I need to get A and B from 'xdot_transformed'
    num_str, den_str = getNumerator(xdot_transformed)
    num_xdotT = Num[]
    den_xdotT = Num[]
    for i in eachindex(xdot_transformed)
        num = eval(Meta.parse(num_str[i]))
        den = eval(Meta.parse(den_str[i]))
        push!(num_xdotT, num)
        push!(den_xdotT, den)
    end

    return equations, TrEquations, xdot, xdot_transformed, num_xdotT, den_xdotT

end
