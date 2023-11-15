#This file is only for the function to get separatly the numerator and denominator.

function getNumerator(eqn3a)

    # Conver to string
    texto = string.(eqn3a)

    # It is supposed that should be the same number the parenthesis in the left side, numerator, than in the
    # right side denominato. So i could count the number of parenthesis and also find when appears '/'
    # and if there are more than one '/'

    # First, how many '/'
    clave = '/'
    for tx in texto

        nveces = count( c -> c == clave, tx)

        if nveces < 1
            # ... el código
        end
    
    end



end


