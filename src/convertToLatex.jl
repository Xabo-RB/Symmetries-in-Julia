function convertToLatex(results, nombre_archivo::String, Discrete_Continous)
    if Discrete_Continous == 1
        ruta_al_archivo = joinpath(raw"C:\Users\xabor\Documents\GitHub\Symmetries\Symmetries in Julia\scripts", "coefficients_Latex_$nombre_archivo.txt")
        open(ruta_al_archivo, "w") do file
            for r in results
                write(file, string(r), "\n", "\n")
            end
        end
    else
        ruta_al_archivo = joinpath(raw"C:\Users\xabor\Documents\GitHub\Symmetries\Symmetries in Julia\scripts", "infinitesimalSys_Latex_$nombre_archivo.txt")
        open(ruta_al_archivo, "w") do file
            for r in results
                write(file, string(r), "\n", "\n")
            end
        end
    end

end