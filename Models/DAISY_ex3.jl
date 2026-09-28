# ________________________DAISY_EX3__________________________
name = "DAISY_EX3"

@variables t

states = ["x1", "x2", "x3"]

salidas = 1

parameters = ["p1", "p3", "p4", "p6", "p7"]

inputs = ["u"]

ecuaciones = [
    "-p1*x1 + x2 + u",
    "p3*x1 - p4*x2 + x3",
    "p6*x1 - p7*x3",
    "x1"
]