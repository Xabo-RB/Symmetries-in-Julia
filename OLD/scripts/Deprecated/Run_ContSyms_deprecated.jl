using DrWatson
using Symbolics
using Latexify


@quickactivate "Symmetries in Julia"

include("Model.jl"); 


stringEstados = CreateModel.estados;
stringParametros = CreateModel.parametros;
stringEntradas = CreateModel.entradas;
stringEcuaciones = CreateModel.ecuaciones;

# 2. ----------  CONVERTIMOS CADA STRING → VARIABLE SIMBÓLICA  ----------------
# Una función que convierte string → variable simbólica del tipo Num
make_var(s) = Num(Symbol(s))  # Esta sigue siendo válida

# Convertimos listas de strings a listas de variables simbólicas
state_syms = [make_var(s) for s in stringEstados]
param_syms = [make_var(p) for p in stringParametros]
input_syms = [make_var(e) for e in stringEntradas]

# 1. Creamos las variables simbólicas correctamente (sin función obsoleta)
vars = [Symbolics.variable(Symbol(s)) for s in stringEstados]


# 2. Las metemos en un diccionario con clave String / la función 'zip' produce Tuplas (x1,x2)
States_dict = Dict{String, Num}()           # `Num` es el tipo genérico de Symbolics
for (s, v) in zip(stringEstados, vars)
    States_dict[s] = v
end


#== 
# 1. Creamos las variables simbólicas correctamente (sin función obsoleta)
vars = [Symbolics.variable(Symbol(s)) for s in stringEstados]
# EXPLICACIÓN DE COMO CREO LAS VARIABLES SIMBÓLICAS
# Equivale a:
vars = Vector{Num}(undef, length(stringEstados))  # Num es el tipo de Symbolics
# Recorremos el índice (i) y el string (s) a la vez
for (i, s) in pairs(stringEstados)

    # 1) Convertimos el string "x1" en el símbolo :x1
    simb = Symbol(s)
    # 2) Lo convertimos en una variable simbólica de Symbolics
    var_simbolica = Symbolics.Variable(simb)
    # 3) Guardamos esa variable en la posición correcta del vector
    vars[i] = var_simbolica
end
==#

