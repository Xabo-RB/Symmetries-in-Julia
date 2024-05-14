# ________________________LLW1987__________________________
name = "LLW1987"

@variables t

states = ["x1", "x2", "x3"]

salidas = 1

parameters = ["theta1","theta2","theta3","theta4"]

inputs = ["u"]

ecuaciones = [
    "-theta1*x1 + theta2*u",
    "-theta3*x2 + theta4*u",
    "-theta1*x3 - theta3*x3 + theta4*x1*u + theta2*x2*u",
    "x3"
]