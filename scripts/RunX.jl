using DrWatson
using Symbolics
using Latexify
using LaTeXStrings
import SymPy as sp
using SymbolicUtils

@quickactivate "Symmetries in Julia"

const THIS_SCRIPT = "RunX.jl"

Discrete_Or_Continous = 'D'

if Discrete_Or_Continous == 'D'


    # Which type of transformation do you want to use?

    #==
    1. Reid transformation (option = 1)
    2. General transformations (option = 2)
    3. Transformations for Observability (option = 3)
    4. Transformations for Structural identifiability (option = 4)
       NOTE: options 1-4 use the ansatz X_i(t, x_i) (only the diagonal of the Jacobian).
    5. SIO, full chain rule, T = t (ECC setting) (option = 5)
    6. SIO, full chain rule, T and input dependence (option = 6)
    ==#

    option = 4
    let
        include("DiscreteSyms.jl")
    end



elseif Discrete_Or_Continous == 'C'

    # Which type of transformation do you want to use?

    #==
    1. Transformations for Observability (option = 1)
    2. Transformations for Structural identifiability (option = 2)
    ==#

    option = 2
    let
        include("LieSyms.jl")
    end


end