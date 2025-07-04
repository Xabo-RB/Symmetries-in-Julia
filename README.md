# Symmetries in Julia

This code base is using the [Julia Language](https://julialang.org/) and
[DrWatson](https://juliadynamics.github.io/DrWatson.jl/stable/)
to make a reproducible scientific project named
> Symmetries in Julia

It is authored by Xabo.

To (locally) reproduce this project, do the following:

0. Download this code base. Notice that raw data are typically not included in the
   git-history and may need to be downloaded independently.
1. Open a Julia console and do:
   ```
   julia> using Pkg
   julia> Pkg.add("DrWatson") # install globally, for using `quickactivate`
   julia> Pkg.activate("path/to/this/project")
   julia> Pkg.instantiate()
   ```

This will install all necessary packages for you to be able to run the scripts and
everything should work out of the box, including correctly finding local paths.

You may notice that most scripts start with the commands:
```julia
using DrWatson
@quickactivate "Symmetries in Julia"
```
which auto-activate the project and enable local path handling from DrWatson.

> Run the code

To start the code the "Run.jl" file must be executed, in VSCode this can be done with "Julia: Execute active File in REPL" with the arrow in the right upper corner.

The model to be analyzed must be described in the script "Model.jl", as it appears now in the example. There are other examples in Models folder. 

The user can select the algorithm to be applied in the run file, modifying two options variables, "Discrete_Or_Continous" and "option". "Discrete_Or_Continous" selects which type of determining system to be computed: 'D' for finite, 'C' for 'infinite'.

Method for finding the Finite Determining system:

1. Reid transformation (option = 1)
2. General transformations (option = 2)
3. Transformations for Observability (option = 3)
4. Transformations for Structural identifiability (option = 4)

Method for finding the Infinite Determining system:

1. Transformations for Observability (option = 1)
2. Transformations for Structural identifiability (option = 2)
