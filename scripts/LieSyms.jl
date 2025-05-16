

include("Model.jl"); 
include(srcdir("functions_conts.jl"))
include(srcdir("convertToMaple.jl"))
include(srcdir("convertToLatex.jl"))


struct symbolic_variables

    S::Vector{Num}
    P::Vector{Num}
    I::Vector{Num}
    DS::Vector{Num}
    EQ::Vector{Num}
    G::Vector{Num}
    Y::Vector{Num}

end

islike(::Num, ::Type{Number}) = true

symbols = FunctionForReading(CreateModel);


if option == 1

    (Julia_result, latex_result)  = mainObsCont(symbols)

elseif option == 2

    (Julia_result, latex_result)  = mainIdentCont(symbols)

end


