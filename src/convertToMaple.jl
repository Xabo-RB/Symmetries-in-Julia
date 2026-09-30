function convertToMaple(coeficientes, nombre_archivo::String, Discrete_Continous)
    if Discrete_Continous == 1
        ruta_al_archivo = joinpath(pwd(), "coefficients_$nombre_archivo.txt")
        open(ruta_al_archivo, "w") do file
            for coeff in coeficientes
                write(file, string(coeff), "\n")
            end
        end
    else
        ruta_al_archivo = joinpath(pwd(), "infinitesimalSys_$nombre_archivo.txt")
        open(ruta_al_archivo, "w") do file
            for coeff in coeficientes
                write(file, string(coeff), "\n")
            end
        end
    end

end
