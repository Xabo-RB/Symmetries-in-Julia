using DrWatson
using Symbolics
using Latexify


@quickactivate "Symmetries in Julia"

include("Model.jl"); 

# Reconocer todas las variables del modelo como strings a variables

stringEstados = CreateModel.estados;
stringParametros = CreateModel.parametros;
stringEntradas = CreateModel.entradas;
stringEcuaciones = CreateModel.ecuaciones;

# Crear variables simbólicas para los estados, parámetros, entradas y ecuaciones

states = ["x1", "x2", "x3", "x4"]

vars = [ Symbolics.Variable(Symbol(s)) for s in stringEstados ]

# Diccionario con clave = nombre (string), valor = la variable simbólica
States_dict = Dict{String, Symbolics.Var}()
for s in stringEstados
    States_dict[s] = Symbolics.Var(Symbol(s))
end

@show var_dict["x1"]
@show var_dict["x2"]