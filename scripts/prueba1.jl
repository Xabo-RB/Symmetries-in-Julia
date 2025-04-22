using DrWatson
using Symbolics, SymbolicUtils
using Latexify


@quickactivate "Symmetries in Julia"

include("Model.jl"); 

# 1) Tus datos de Model.jl
stringEstados    = CreateModel.estados
stringParametros = CreateModel.parametros
stringEntradas   = CreateModel.entradas
stringEcuaciones = CreateModel.ecuaciones

# 2) Declarar todas las variables simbólicas a la vez usando el macro @variables y evaluando la cadena generada
decl = "@variables " *
       join(stringEstados,   " ") * " " *
       join(stringParametros," ") * " " *
       join(stringEntradas,  " ")
eval(Meta.parse(decl))  # Convierte el string en una expresión Julia y la evalúa para declarar las variables simbólicas


# 3) Ahora reconstruyo mis vectores con esos mismos objetos Num:
state_syms = []
for s in stringEstados
    simb = Symbol(s)         # Convertir el string a símbolo Julia (:x1, :x2, etc.)
    obj  = eval(simb)        # Evaluar el símbolo, que ya ha sido definido como variable simbólica
    push!(state_syms, obj)   # Añadir el objeto simbólico al vector
end
param_syms = []
for p in stringParametros
    simb = Symbol(p)
    obj  = eval(simb)
    push!(param_syms, obj)
end
input_syms = []
for u in stringEntradas
    simb = Symbol(u)
    obj  = eval(simb)
    push!(input_syms, obj)
end

# 4) Parseo y evalúo cada ecuación (ya usan exactamente esos x1,x2,…):
symbolic_expressions = []
for eq in stringEcuaciones
    parsed_expr = Meta.parse(eq)  # Convertir el string en una expresión Julia (Expr)
    symbolic_eq = eval(parsed_expr)  # Evaluar esa expresión usando las variables simbólicas declaradas
    push!(symbolic_expressions, symbolic_eq)  # Añadir la expresión al vector de expresiones simbólicas
end

# 5) Construyo el jacobiano de las primeras 4 ecuaciones respecto a los 4 estados:
J = Symbolics.jacobian(symbolic_expressions[1:4], state_syms)


