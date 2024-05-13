# Number of states
valor_nx = 4
#Number of outputs
ny = 1

# ODE system, and output equations at the end
ecuaciones = [
    "- (-(k21+k31+k41+k01)*x1(t) + k12*x2(t) + k13*x3(t) + k14*x4(t) + u)",
    "k21*x1(t) - k12*x2(t)",
    "k31*x1(t) - k13*x3(t)",
    "k41*x1(t) - k14*x4(t)",
    "x1(t)"
]

with open("script.mpl", "w") as file:
    file.write("#restart:\n")
    file.write(f"nx := {valor_nx}:\n") # La f antes de la cadena indica que se trata de un "f-string", una característica de Python 3.6+ que permite la interpolación de cadenas. La f hace que cualquier cosa entre llaves {} en la cadena sea una expresión que se evaluará y se insertará en la cadena. Es una forma muy conveniente de crear cadenas que incluyan variables o expresiones.
    file.write(f"ny := {ny}:\n")
    file.write(f"f := Array(1..{valor_nx+ny});\n")
    file.write(f"Xt := Array(1..{valor_nx});\n")
    file.write(f"Tt := Array(1..{valor_nx});\n")
    file.write(f"F := Array(1..{valor_nx});\n")
    file.write("\n")
    
    # Escribe cada ecuación en el archivo
    for i, ecuacion in enumerate(ecuaciones, 1):
        file.write(f"f[{i}] := {ecuacion};\n")
    
    for i in range(1,valor_nx+1):
        file.write("\n")
        file.write(f"Xt[{i}] := diff(X{i}(t, x{i}(t)),t);\n")
        file.write(f"Tt[{i}] := diff(T(t, x{i}(t)),t);\n")
    
    file.write("\n")
    file.write("for i from 1 to nx do\n")
    file.write("    F[i] := subs(")
    for i in range(1,valor_nx+1):
        file.write(f"x{i}(t) = X{i}(x{i},t),")
    file.write(" f[i]):\n")
    file.write("end do:\n")