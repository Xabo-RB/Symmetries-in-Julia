using DrWatson
using Symbolics
using Latexify
using LaTeXStrings
import SymPy as sp
using SymbolicUtils
using ArgParse

#________ Handle Parsed Arguments _________#

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin
        "--option"
            help = "symmetry option, see README"
	    default = 1
	    arg_type = Int
        "--discrete"
            help = "enable discrete symmetry"
            action = :store_true
        "model"
            help = "model file"
            required = true
    end

    return parse_args(s)
end

parsed_args = parse_commandline()
println("Parsed args:")
for (arg,val) in parsed_args
    println("  $arg  =>  $val")
end

option = parsed_args["option"]
discrete = parsed_args["discrete"]
model = parsed_args["model"]

#________ Define Model _________#

include(model)

struct userDefined

    estados::Vector{String}
    nSalidas::Int
    parametros::Vector{String}
    entradas::Vector{String}
    ecuaciones::Vector{String}

end

CreateModel = userDefined(states,salidas,parameters,inputs,ecuaciones)

#________ Run Code _________#

@quickactivate "Symmetries in Julia"

if discrete

    # Which type of transformation do you want to use?

    #==
    1. Reid transformation (option = 1)
    2. General transformations (option = 2)
    3. Transformations for Observability (option = 3)
    4. Transformations for Structural identifiability (option = 4)
    ==#

    option = 4
    let
        include("DiscreteSyms.jl");
    end

else

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