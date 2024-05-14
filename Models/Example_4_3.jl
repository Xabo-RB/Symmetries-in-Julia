# ________________________ Example 4.3 SEIR __________________________ NOT YET WORKING
name = "Example_4_3_SEIR"

@variables t

states = ["S", "E", "I", "R", "Q"]

salidas = 1

parameters = ["beta","v","psi","gamma"]

inputs = []

ecuaciones = [
    "-beta*S*I",
    "beta*S*I - v*E",
    "v*E - psi*I -(1-psi)*gamma*I",
    "gamma*Q +(1-psi)*gamma*I",
    "-gamma*Q + psi*I",
    "Q"
]
