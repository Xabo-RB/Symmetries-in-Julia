using DrWatson
using Symbolics
using Latexify


@quickactivate "Symmetries in Julia"

include("Model.jl"); CreateModel

# Reconocer todas las variables del modelo como strings a variables

stringEstados = CreateModel.states;
stringParametros = CreateModel.parameters;
stringEntradas = CreateModel.inputs;
stringEcuaciones = CreateModel.ecuaciones;

