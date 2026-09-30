include(srcdir("functions_conts.jl"))
include(srcdir("convertToMaple.jl"))
include(srcdir("convertToLatex.jl"))
include(srcdir("FiniteDeterminingSystem.jl"))   # full chain rule (options 3 to 6)


struct symbolic_variables

    S::Vector{Num}
    P::Vector{Num}
    I::Vector{Num}
    DS::Vector{Num}
    EQ::Vector{Num}
    G::Vector{Num}
    Y::Vector{Num}

end

if THIS_SCRIPT == "RunX.jl"
    include("Model.jl"); 
end

islike(::Num, ::Type{Number}) = true

symbols = FunctionForReading(CreateModel);


if option == 1

    (Julia_result, latex_result)  = mainObsCont(symbols)

elseif option == 2

    (Julia_result, latex_result)  = mainIdentCont(symbols)

elseif option == 3
    # Observability, full chain rule: V = xi(t,x).d_x; output included
    runDeterminingSystem(CreateModel, name, "Obs"; infinitesimal = true, transform_params = false)

elseif option == 4
    # Structural identifiability, full chain rule, ECC setting: V = xi.d_x + zeta.d_p
    runDeterminingSystem(CreateModel, name, "SI"; infinitesimal = true)

elseif option == 5
    # Structural identifiability with tau and input dependence
    runDeterminingSystem(CreateModel, name, "SI_timeT_udep"; infinitesimal = true,
                         time_transform = true, input_dependence = true)

elseif option == 6
    # General transformation (draft, Section 2, eq. (11)): V = tau d_t + xi.d_x + eta.d_u;
    # no parameters transformed and no output
    runDeterminingSystem(CreateModel, name, "General"; infinitesimal = true,
                         time_transform = true, input_dependence = true, transform_params = false,
                         transform_inputs = true, include_output = false)

end


