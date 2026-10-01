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
    Full chain rule (src/FiniteDeterminingSystem.jl):
    5. Structural identifiability, T = t (ECC setting) (option = 5)
    6. Structural identifiability, T and input dependence (option = 6)
    7. Observability, T = t (option = 7)
    8. General transformation T, X, U, no output (draft Section 2) (option = 8)
    ==#

    option = 6
    let
        include("DiscreteSyms.jl")
    end



elseif Discrete_Or_Continous == 'C'

    # Which type of transformation do you want to use?

    #==
    1. Transformations for Observability (option = 1)
    2. Transformations for Structural identifiability (option = 2)
       NOTE: options 1-2 build the prolongation with the diagonal only.
    Full chain rule (src/FiniteDeterminingSystem.jl):
    3. Observability (option = 3)
    4. Structural identifiability, tau = 0 (ECC setting) (option = 4)
    5. Structural identifiability, tau and input dependence (option = 5)
    6. General transformation tau, xi, eta, no output (draft Section 2) (option = 6)
    ==#

    option = 2
    let
        include("LieSyms.jl")
    end


end