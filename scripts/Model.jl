#_____________________________ User defined _____________________________#

#==
# ________________________Bilirubin2__________________________
name = "Bilirubin2"

@variables t

states = ["x1", "x2", "x3", "x4"]

salidas = 1

parameters = ["k01","k12","k21","k13","k31","k14","k41"]

inputs = ["u"]

ecuaciones = [
    "- (-(k21+k31+k41+k01)*x1 + k12*x2 + k13*x3 + k14*x4 + u)",
    "k21*x1 - k12*x2",
    "k31*x1 - k13*x3",
    "k41*x1 - k14*x4",
    "x1"
]



# ________________________Example 4.3__________________________
name = "SEIR"

@variables t

states = ["x1", "x2", "x3", "x4", "x5"]

salidas = 1

parameters = ["beta1","nu1","psi1","gamma1"]

inputs = []

ecuaciones = [
    "-beta1*x1*x3",
    "beta1*x1*x3 - nu1*x2",
    "nu1*x2 - psi1*x3 - (1-psi1)*gamma1*x3",
    "psi1*x3 - gamma1*x4",
    "(1-psi1)*gamma1*x3 + gamma1*x4",
    "x4"
]
==#

# ________________________Example 4.3 New__________________________
name = "SEIRT"

@variables t

states = ["x1", "x2", "x3", "x4"]

salidas = 1

parameters = ["k1", "k2", "k3"]
#parameters = ["b","alph","lamb"]

inputs = []

ecuaciones = [
    "-k1*x1*x3",
    "k1*x1*x3 - k2*x2",
    "k2*x2 - k3*x3",
    "k3*x3",
    "x3"
]

# __________________________________________________
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


#_________________________________________________________________________#
name = "Goodwin"

states = ["x1", "x2", "x3", "x4"]

salidas = 1

parameters = ["k1", "k2", "k3" , "k4", "k5", "k6", "k7"]
#parameters = ["b", "c", "alpha", "beta", "gama", "delta", "sigma"]

inputs = []

ecuaciones = [
    "-k1*x1 + 1 / (k2 + x4)",
    "k3*x1 - k4*x2",
    "k5*x2 - k6*x3",
    "k7*x4* (k5*x2 - k6*x3)/x3",
    "x1"
]

#_________________________________________________________________________#
name = "SlowFast"

states = ["xA", "xB", "xC"]

salidas = 2

parameters = ["k1", "k2", "eB"]

inputs = ["u1", "u2"]

ecuaciones = [
    "-k1 * xA",
    "k1*xA - k2*xB",
    "k2*xB",
    "xC",
    "u1*xA + eB*xB + u2*xC"
]


#_________________________________________________________________________#

#_________________________________________________________________________#

#_________________________________________________________________________#

struct userDefined

    estados::Vector{String}
    nSalidas::Int
    parametros::Vector{String}
    entradas::Vector{String}
    ecuaciones::Vector{String}

end

CreateModel = userDefined(states,salidas,parameters,inputs,ecuaciones)
