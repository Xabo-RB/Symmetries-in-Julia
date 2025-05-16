using DrWatson
using Symbolics
using Latexify
using LaTeXStrings
import SymPy as sp
using SymbolicUtils

@quickactivate "Symmetries in Julia"

Discrete_Or_Continous = 'D'

if Discrete_Or_Continous == 'D'


    # Which type of transformation do you want to use?

    #==
    1. Reid transformation (option = 1)
    2. General transformations (option = 2)
    3. Transformations for Observability (option = 3)
    4. Transformations for Structural identifiability (option = 4)
    ==#

    option = 3
    let
        include("DiscreteSyms.jl");
    end



elseif Discrete_Or_Continous == 'C'

    # Which type of transformation do you want to use?

    #==
    1. Transformations for Observability (option = 1)
    2. Transformations for Structural identifiability (option = 2)
    ==#

    option = 2
    let
        include("LieSyms.jl");
    end


end