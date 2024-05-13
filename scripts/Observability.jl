#__________________________________________________________________________________________
#__________________________________________________________________________________________

# --------------------- Method for Observability ---------------------
# This script is to obtain the coefficients of the determinig system corresponding to equation (15)
# of section 3. I.e. transformations in chain derivatives (13b).
# -----------------------------------------------------------------------------------------------

function Observability(CreateModel, name)
    

    #CreateModel = userDefined(states,salidas,parameters,inputs,ecuaciones)
    #Model = userDefined(states,salidas,parameters,inputs,ecuaciones)

    function getDeterminingSystemComplete(Model,t)

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
        for i in eachindex(Model.ecuaciones)[1:end-Model.nSalidas]
            str = Meta.parse(Model.ecuaciones[i])
            eqn1 = eval(str)
            push!(equations, eqn1)

            transf_eqn = transformVariables(equations[i], St, transSt) 
            push!(TrEquations, transf_eqn)
        end

        equationsY = Num[]
        TrEquationsY = Num[]
        #for i in eachindex(Model.ecuaciones)[end-Model.nSalidas+1:end]
        j = 1
        for i in (length(Model.ecuaciones) - Model.nSalidas + 1):length(Model.ecuaciones)
            str = Meta.parse(Model.ecuaciones[i])
            eqn1 = eval(str)
            push!(equationsY, eqn1)

            transf_eqn = transformVariables(equationsY[j], St, transSt) 
            push!(TrEquationsY, transf_eqn)
            j += 1
        end


        #To pass variables to the Model Struct
        M = ModelSymObs(St,transSt,pr,inU,equations,equationsY)

        # ---------------------- CHAIN DER --------------------- #
        estado = M.states
        estM = M.TransStates 

        # Creates the differential operators
        Dt = Differential(t)

        dotx = Num[]

        for (i, value) in enumerate(estado)
            # Partial erivative with respect a estado[i]
            Dx = Differential(value)

            # Define the variables T(t,x1(t)) as Tx1, Tx2, ...
            str = "@variables T"
            eval(Meta.parse(str))

            # Calculate the total derivative of X with respect to time. estM = X1, X2, ...
            dX_dt = Dt(estM[i]) + Dx(estM[i]) * Dt(estado[i])

            dotxEle = dX_dt

            push!(dotx, dotxEle)

        end

        xdot = copy(dotx)

        function creatingDifferentialComplete(mod)
            # Vector with all de variable names, states and Mayusculas States as strings
            nombresVar = map(string, mod.states)
            nombresVarT = map(string, mod.TransStates)

            # A's coefficients dXi/dt
            As = []
            for nombre in nombresVarT
                derivada_str = "Differential(t)($(nombre))"
                push!(As, derivada_str)
            end

            # B's coefficients dXi/dxi
            Bs = []
            for i in eachindex(nombresVarT)
                derivada_str = "Differential($(nombresVar[i]))($(nombresVarT[i]))"
                push!(Bs, derivada_str)
            end

            # derivadas primera coefficients dxi/dt
            xdot1 = []
            for i in eachindex(nombresVarT)
                derivada_str = "Differential(t)($(nombresVar[i]))"
                push!(xdot1, derivada_str)
            end 

            return (As, Bs, xdot1)
        end

        tuplaDerivadas = creatingDifferentialComplete(M)

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
        xdot1_str = Num[]
        xdot11 = tuplaDerivadas[3]
        for deriv_str in xdot11
            expr_julia = Meta.parse(deriv_str)
            expr_simbolica = eval(expr_julia)
            push!(xdot1_str, expr_simbolica)
        end

        function creatingCoeffsForDiffsObs(mod)
            nombresVar = map(string, mod.states)
            nombresVarT = map(string, mod.TransStates)

            #d(States)/dt
            A_dSdt = Num[]
            for names in nombresVarT
                # A's: dXi/dt : Xit : /State/t
                str = "@variables $(names)t"
                eval(Meta.parse(str))
                varsym = eval(Meta.parse("$(names)t"))
                push!(A_dSdt, varsym)
            end

            #d(States)/d(states)
            B_dSds = Num[]
            for i in eachindex(nombresVarT)
                # B's: dSi/dsi : Sisi : /Statei//statei/
                str = "@variables $(nombresVarT[i]nombresVar[i])"
                eval(Meta.parse(str))
                varsym = eval(Meta.parse("$(nombresVarT[i]nombresVar[i])"))
                push!(B_dSds, varsym)
            end

            #d(states)/dt
            D_dsdt = Num[]
            for i in eachindex(nombresVarT)
                # D's: dsi/dt : sit : /statei/t
                str = "@variables $(nombresVar[i])t"
                eval(Meta.parse(str))
                varsym = eval(Meta.parse("$(nombresVar[i])t"))
                push!(D_dsdt, varsym)
            end

            return (A_dSdt, B_dSds, D_dsdt)

        end

        coeficientes = creatingCoeffsForDiffsObs(M)

        # For substituting I use 'coeficientes' and 'tuplaStringsNums'
        # Substitute the coefficients in the equation xdot.
        tuplaStringsNums = (As, Bs, xdot1_str)
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
        
        #num_str, den_str = getNumerator(xdot_transformed)
        num_str = string.(xdot_transformed)

        num_xdotT = Num[]
        for i in eachindex(xdot_transformed)
            num = eval(Meta.parse(num_str[i]))
            push!(num_xdotT, num)
        end

        #Substitute dxdt por la ecuación diferencial de dicho estado
        finalNum = Num[]
        for i in eachindex(num_xdotT)
            # Differential equations
            substituyoEsto = coeficientes[3]
            #dsi/dt
            porEsto = equations
            varsym = transformVariables(num_xdotT[i], substituyoEsto, porEsto) 
            push!(finalNum, varsym)
        end

        # Now: A/B = (...) -> A = (...)B -> (...)B - A
        finalSol = Num[]
        finalSol1 = Num[]
        for i in eachindex(finalNum)
            new = TrEquations[i] - finalNum[i]
            new1 = expand(new)
            push!(finalSol, new)
            push!(finalSol1, new1)
        end

        for i in eachindex(TrEquationsY)
            solY = equationsY[i] - TrEquationsY[i]
            solY1 = expand(solY)
            push!(finalSol, solY)
            push!(finalSol1, solY1)
        end

        return finalSol, finalSol1
    end

    determiningSystem, determiningSystemExpanded = getDeterminingSystemComplete(CreateModel,t)

    coeffs = coefficients(determiningSystem)
    
    for eq in coeffs
        latex_expr = latexify(eq)
        render(latex_expr)
    end

    #print(coeffs)

    convertToMaple(coeffs, name)

end