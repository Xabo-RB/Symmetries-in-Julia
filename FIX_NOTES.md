# Fix notes: determining systems with the full chain rule

## The problem

All builders compute the total derivative of the transformed state `X_i` using only the
partial derivative with respect to its own state `x_i` (ansatz `X_i(t, x_i)`, as in the comment
of `chainDer` and in the Maple scripts `X1(t, x1(t))`):

| File | Line (original) | Code |
|---|---|---|
| `src/GeneralTransformation.jl` (finite, option 2) | 81, 85 | `Dt(T) + Dx(T) * Dt(estado[i]) + ...`, `Dt(estM[i]) + Dx(estM[i]) * Dt(estado[i]) + ...` |
| `src/Observability.jl` (finite, option 3) | 98 | `Dt(estM[i]) + Dx(estM[i]) * Dt(estado[i])` |
| `src/StructuralIdentifiability.jl` (finite, option 4) | 114 | same |
| `src/functions.jl` (`chainDer`) | 27, 30 | same |
| `src/functions_conts.jl` (infinitesimal, options 1–2) | 211, 432 | `epsi_x_syms[i]*variables.DS[i]` |

The draft (main.tex) and the ECC paper use vector notation: in eq. (2b) `X_x xdot` is the Jacobian
matrix times a vector and `T_x . xdot` a dot product, and eq. (2a) has `X(t, x, u)` depending on the
whole vector x. In components:

    dX_i/dt = X_i,t + sum_j X_i,x_j * f_j + X_i,u * u_t
    dT/dt   = T_t   + sum_j T_x_j   * f_j + T_u   * u_t     (the SAME in every equation)
    xi_i^(1) = xi_i,t + sum_j xi_i,x_j * f_j                  (infinitesimal, eq. (9a) of the ECC)

Consequences: symmetries that mix states cannot be found (permutations as in ECC Example 1,
`X2 = x2 + a*x1` in DAISY_EX3, ...); an additive input in the equation of `x1` only enters the first
equation instead of all of them. The parameter equations of option 4 were already correct.

Also in the infinitesimal code (`functions_conts.jl`, line 381) the parameter equation is built as
`sum(zeta_t) + sum(zeta_x) * f_j`, mixing all parameters, instead of
`zeta_k,t + sum_j zeta_k,x_j * f_j = 0` for each parameter `k` (eq. (26) of the draft).
(The diagonal taken at line 143 is harmless: that Jacobian, d g / d xdot, is the identity.)

## The fix: `src/FiniteDeterminingSystem.jl`

One file with both builders, `finiteDeterminingSystem` and `infinitesimalDeterminingSystem`, and
the options `time_transform`, `input_dependence`, `transform_params`, `transform_inputs`,
`include_output`. They are wired into the run scripts as:

| Case | Finite (`'D'`) | Infinitesimal (`'C'`) | Output files tag |
|---|---|---|---|
| Structural identifiability, `T = t` (ECC setting) | option 5 | option 4 | `SI` |
| Structural identifiability, `T` and input dependence | option 6 | option 5 | `SI_timeT_udep` |
| Observability, `T = t`, parameters fixed | option 7 | option 3 | `Obs` |
| General transformation `T, X, U`, no output (draft Section 2) | option 8 | option 6 | `General` |

Finite equations (`D(F) = F_t + sum_j F_x_j f_j + F_u u_t`):

    states     : f_i(T, X, U, P) * D(T) - D(X_i) = 0      (D(T) = 1 when T = t)
    parameters : D(P_k) = 0
    outputs    : h_l(X, u, P) - h_l(x, u, p) = 0

Infinitesimal equations (`V(g) = tau g_t + xi . g_x + zeta . g_p + eta . g_u`):

    states     : D(xi_i) - f_i D(tau) - V(f_i) = 0
    parameters : D(zeta_k) = 0
    outputs    : V(h_l) = 0

Splitting: always with respect to `u_t`; with respect to powers of `u` only when nothing depends
on `u`. When the unknowns depend on `u`, `u` is a coordinate and cannot be split.

Names of the unknowns
* finite: same as in the rest of the repo, `X1`, `X1t`, `X1x2`, `X1u`, `T`, `Tt`, `Tx1`, `Tu`,
  `P1`, `P1t`, `P1x2`, `U`, `u_t`;
* infinitesimal: `tau`, `xi_x1`, `zeta_p1`, `eta_u` and derivatives `tau_t`, `tau_x1`, `xi_x1_t`,
  `xi_x1_x2`, `xi_x1_u`, `zeta_p1_x2`, ... (the underscore avoids ambiguous names).

Output: `equations_<name>_<tag>.txt` and `coefficients_<name>_<tag>.txt` (prefix `infinitesimal_`
for the infinitesimal system) in the working folder.

Other changes
* `Models/Bilirubin2.jl` and the commented copy in `scripts/Model.jl`: removed the extra minus sign
  in front of the equation of `x1` (now as in ECC eq. (13)). Old results in `Results/` were
  computed with the wrong sign and with the diagonal-only chain rule.
* The old options (finite 1–4, infinitesimal 1–2) are kept unchanged for reproducibility, with a
  warning comment next to the affected lines. Do not use them for conclusions.

## How to check it

1. Julia self-test: run `scripts/TestFiniteDetSys.jl`; the expected output is listed at the top of
   the file (finite: swap, family, time shift, observability swap; infinitesimal: DAISY_EX3
   generators and Werner's Example 6.4 field for Nick's model).
2. Python cross-check (same equations, same names): `python3 scripts/reference_detsys.py` and
   `python3 scripts/reference_detsys.py --extra`. It writes `Results/reference_DAISY_EX3_*` files to
   compare with the Julia output.

Note: this code could not be executed in Julia when it was written (it was syntax-checked with a
Julia parser, and the same equations were run in Python). Please run the self-test first.

## Not changed, on purpose

* Draft (main.tex), eqs. (24a)-(24b): the terms `(xi_x - 1)` and `(zeta_theta - 1)` are wrong; with
  tau = 0, eq. (9) gives `xi^(1) = xi_t + xi_x xdot + xi_theta thetadot` and
  `zeta^(1) = zeta_t + zeta_x xdot + zeta_theta thetadot` (as in ECC eqs. (9a)-(9b)). This is text in
  the Overleaf project, not code. The code already removed this "-1" (commented block at line 422).
* The time-transform settings (finite option 6, infinitesimal option 5) admit the time shift
  `T = t + c` in every autonomous model, e.g. DAISY_EX3 with input, which is at least locally
  identifiable. This is not a bug of the code but a property of allowing time transformations,
  which is the open question discussed with Werner and Nick.
