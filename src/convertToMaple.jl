function convertToMaple(coeficientes)
    ruta_al_archivo = raw"C:\Users\xabor\Documents\GitHub\Symmetries\Symmetries in Julia\\scripts\coefficients.txt"
    open(ruta_al_archivo, "w") do file
        for coeff in coeficientes
            write(file, string(coeff), "\n")
        end
    end

end
