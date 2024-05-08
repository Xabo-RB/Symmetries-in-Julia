function convertToMaple(coeficientes, nombre_archivo::String)
    ruta_al_archivo = joinpath(raw"C:\Users\xabor\Documents\GitHub\Symmetries\Symmetries in Julia\scripts", "coefficients_$nombre_archivo.txt")
    open(ruta_al_archivo, "w") do file
        for coeff in coeficientes
            write(file, string(coeff), "\n")
        end
    end

end
