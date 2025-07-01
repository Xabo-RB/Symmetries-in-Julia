using DrWatson
using Symbolics
using Latexify
using LaTeXStrings
import SymPy as sp
using SymbolicUtils
using ArgParse

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin
        "--option"
            help = "symmetry option"
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