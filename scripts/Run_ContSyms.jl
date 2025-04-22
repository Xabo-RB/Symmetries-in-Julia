
using Symbolics            # para Num, etc.
using ModelingToolkit      # ¡aquí está @parameters!
using Symbolics: @variables
using SymbolicUtils: islike
using Latexify



include("Model.jl"); 

# Reconocer todas las variables del modelo como strings a variables

stringEstados = CreateModel.estados;
stringParametros = CreateModel.parametros;
stringEntradas = CreateModel.entradas;
stringEcuaciones = CreateModel.ecuaciones;



# 2. ----------  CONVERTIMOS CADA STRING → VARIABLE SIMBÓLICA  ----------------
# Una función que hace la labor de dos funciones:
make_var(s) = Num(Symbol(s))
# ...
state_syms = [make_var(s) for s in stringEstados]     
param_syms = [make_var(p) for p in stringParametros] 
input_syms = [make_var(e) for e in stringEntradas]  

#== EXPLICACIÓN DE COMO CREO LAS VARIABLES SIMBÓLICAS
# 1. Creamos las variables simbólicas (devuelve `Num` o `Term`)
 vars = [Symbolics.Variable(Symbol(s)) for s in stringEstados]

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

# 3. ----------  DICCIONARIOS ÚTILES (por nombre de texto) --------------------
States_dict   = Dict(stringEstados   .=> state_syms)
Params_dict   = Dict(stringParametros.=> param_syms)
Inputs_dict   = Dict(stringEntradas  .=> input_syms)


# 4. ----------  MAPA SIMBÓLICO PARA SUBSTITUIR O EVALUAR ---------------------
#    clave = :x1, valor = x1   (ambos son Symbol / Num según convenga)
symmap = Dict{Symbol, Num}()

for D in (States_dict, Params_dict, Inputs_dict)   # recorremos cada diccionario
    for (name, sym) in D                           # ahora sí, cada Pair dentro
        symmap[Symbol(name)] = sym
    end
end
for (name, sym) in symmap
    @eval const $(name) = $sym
end


function str2num(str)
    ex = Meta.parse(str)
    return eval(ex)        # ya x1, k21, u… están definidos como Num
end

ecuaciones_symb = [str2num(eq) for eq in stringEcuaciones]

@show typeof(ecuaciones_symb[1])  # ⇒ Num


#==
# 5A. ---------  OPCIÓN “SIN eval”: Meta.parse + substitute  ------------------
ecuaciones_symb = [
    Symbolics.substitute(Meta.parse(eq), symmap) for eq in stringEcuaciones
]

# 5. ---------  OPCIÓN “CON eval” (más corta, pero global) -------------------
for D in (States_dict, Params_dict, Inputs_dict)   # 1º: cada diccionario
    for (name, sym) in D                           # 2º: cada par clave‑valor
        @eval const $(Symbol(name)) = $sym         # define x1, k21, u, …
    end
end
==#
#==
# Ahora SÍ puedes evaluar las cadenas:
ecuaciones_symb = [eval(Meta.parse(eq)) for eq in stringEcuaciones]

# 2. Las metemos en un diccionario con clave String / la función 'zip' produce Tuplas (x1,x2)
States_dict = Dict{String, Num}()           # `Num` es el tipo genérico de Symbolics
for (s, v) in zip(stringEstados, vars)
    States_dict[s] = v
end
==#