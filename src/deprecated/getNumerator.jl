#This file is only for the function to get separatly the numerator and denominator.

function getNumerator(eqn3a)
    # Conver to string
    texto = string.(eqn3a)

    # It is supposed that should be the same number the parenthesis in the left side, numerator, than in the
    # right side denominato. So i could count the number of parenthesis and also find when appears '/'
    # and if there are more than one '/'

    # First, how many '/'
    clave = '/'

    NUM = String[]
    DEN = String[]

    for tx in texto

        nveces = count( c -> c == clave, tx)

        if nveces == 1
            # Where is the /
            donde = findfirst(==(clave), tx)
            # Cut the string in Numerator and Denominator
            numerador = tx[1:donde-1]
            denominador = tx[donde+1:end]

            # Check if there is the same number of Parenthesis in numerator and denominator
            clavep = '('
            clavep1 = ')'
            nParentNum = count( d -> d == clavep, numerador)
            nParentNum1 = count( e -> e == clavep1, numerador)
            nParentDen = count( d -> d == clavep, denominador)
            nParentDen1 = count( e -> e == clavep1, denominador)

            # If there are more '(' than ')' or inverse, it will say error (I need to implement another function
            # for that). If there are the same number of '(' than ')', the num and den are good separated.
            if nParentNum != nParentNum1 && nParentDen != nParentDen1
                println("Equation is not basic (Num)/(Den)")
                push!(NUM,"ERROR")
                push!(DEN,"ERROR")
            elseif nParentNum == nParentNum1 && nParentDen == nParentDen1
                push!(NUM,numerador)
                push!(DEN,denominador)
            end
        end    
    end

    return NUM, DEN

end


