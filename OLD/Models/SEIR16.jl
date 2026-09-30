name = "SEIR16"

@variables t

states = ["x1", "x2", "x3", "x4"]

salidas = 1

parameters = ["k1", "k2", "k4", "k5", "k6"]
#parameters = ["beta","epsilon","rho", "mu", "delta"]

inputs = []

ecuaciones = [
    "-k1*x1*x3",
    "k1*x1*x3 - k2*x2",
    "k2*x2 - (k4+k5)*x3",
    "k4*x3-k6*x4",
    "k5*x3"
]