using DrWatson
using Symbolics, SymbolicUtils
using Latexify


@quickactivate "Symmetries in Julia"

include("Model.jl"); 
include("functions_conts.jl")

struct symbolic_variables

    S::Vector{Num}
    P::Vector{Num}
    I::Vector{Num}
    DS::Vector{Num}
    EQ::Vector{Num}
    G::Vector{Num}

end

islike(::Num, ::Type{Number}) = true

symbols = FunctionForReading(CreateModel);

# ----------------- 1º FUNCION ----------------- #
# Para comprobar:
#epsi, epsiJg, Jg = funcion1era(symbols)
# 
epsiJg = funcion1era(symbols)

# ----------------- 2º FUNCION ----------------- #
# d [xdot_i - f_i]/ d xdot_i
dgdx = funcion2da(symbols)

# ----------------- 3º FUNCION ----------------- #
# COMPROBACIÓN, tiene que dar 4
#expr = symbols.G[1] + 4 + symbols.G[2]
expr_subsDX = funcion3era(expr, symbols)






#==
# 1) Tus datos de Model.jl
stringEstados    = CreateModel.estados
stringParametros = CreateModel.parametros
stringEntradas   = CreateModel.entradas
stringEcuaciones = CreateModel.ecuaciones[1:4]

# 2) Declarar todas las variables simbólicas a la vez usando el macro @variables y evaluando la cadena generada
decl = "@variables " *
       join(stringEstados,   " ") * " " *
       join(stringParametros," ") * " " *
       join(stringEntradas,  " ")

decl_dx = decl * " " * join([ "d" * s for s in stringEstados ], " ")
eval(Meta.parse(decl_dx))  # Convierte el string en una expresión Julia y la evalúa para declarar las variables simbólicas


# 3) Ahora reconstruyo mis vectores con esos mismos objetos Num:
state_syms = Num[]
for s in stringEstados
    simb = Symbol(s)         # Convertir el string a símbolo Julia (:x1, :x2, etc.)
    obj  = eval(simb)        # Evaluar el símbolo, que ya ha sido definido como variable simbólica
    push!(state_syms, obj)   # Añadir el objeto simbólico al vector
end
param_syms = Num[]
for p in stringParametros
    simb = Symbol(p)
    obj  = eval(simb)
    push!(param_syms, obj)
end
input_syms = Num[]
for u in stringEntradas
    simb = Symbol(u)
    obj  = eval(simb)
    push!(input_syms, obj)
end

Dstate_syms = [ eval(Symbol("d"*s))   for s in stringEstados ]

# 4) Parseo y evalúo cada ecuación (ya usan exactamente esos x1,x2,…):
symbolic_expressions = []
for eq in stringEcuaciones
    parsed_expr = Meta.parse(eq)  # Convertir el string en una expresión Julia (Expr)
    symbolic_eq = eval(parsed_expr)  # Evaluar esa expresión usando las variables simbólicas declaradas
    push!(symbolic_expressions, symbolic_eq)  # Añadir la expresión al vector de expresiones simbólicas
end

# 4) gᵢ = dxi – fi 
g = Vector{typeof(Dstate_syms[1])}()
for i in eachindex(Dstate_syms, symbolic_expressions)
    push!(g, Dstate_syms[i] - symbolic_expressions[i])
end

Jg = Symbolics.jacobian(g, state_syms)
==#
