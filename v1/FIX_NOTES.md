# Fix notes: finite determining system with the full chain rule

## The problem

All the finite builders compute the total derivative of the transformed state `X_i` using
only the partial derivative with respect to its own state `x_i`:

| File | Line (original) | Code |
|---|---|---|
| `src/GeneralTransformation.jl` (option 2) | 81, 85 | `dT_dt = Dt(T) + Dx(T) * Dt(estado[i]) + ...` and `dX_dt = Dt(estM[i]) + Dx(estM[i]) * Dt(estado[i]) + ...` |
| `src/Observability.jl` (option 3) | 98 | `dX_dt = Dt(estM[i]) + Dx(estM[i]) * Dt(estado[i])` |
| `src/StructuralIdentifiability.jl` (option 4) | 114 | same |
| `src/functions.jl` (`chainDer`) | 27, 30 | same |

This corresponds to the ansatz `X_i(t, x_i)` written in the comment of `chainDer` and in the
Maple scripts (`X1(t, x1(t))`, ...). In the draft (main.tex) and in the ECC paper the formulas are
written in vector notation: in eq. (2b) `X_x xdot` is the Jacobian matrix times a vector and
`T_x . xdot` a dot product, and eq. (2a) has `X(t, x, u)` depending on the whole vector x. In
components, the chain rule requires

    dX_i/dt = X_i,t + sum_j X_i,x_j * f_j + X_i,u * u_t
    dT/dt   = T_t   + sum_j T_x_j   * f_j + T_u   * u_t     (the SAME in every equation)

Consequences:

* Symmetries that mix states cannot be found: permutations (`X2 = x3`, ECC Example 1),
  `X2 = x2 + a*x1`, `X3 = x3 + (p7 - p4)*x2` (DAISY_EX3), etc.
* With an additive input in the equation of `x1`, the input only appears in the first equation.
  With the full chain rule it also appears in the others through `X_i,x1 * u` and `T_x1 * u`;
  these are exactly the terms that explain why DAISY_EX3 changes when the input is removed.
* In option 2, `dT/dt` is different in each equation (it must be one and the same function).

Option 2 additionally does not transform the parameters, has no output condition, and uses the
global `u` even when the model has no inputs (it only runs if `u` exists in the session).

The parameter equations in option 4 are correct (they sum over all states); only the state
equations are affected. The saved file `Results/coefficients_Bilirubin2_SI.txt` shows the
diagonal structure (`X2x2` but no `X2x1`, `X2x3`, ...).

## The fix

New file `src/FiniteDeterminingSystem.jl`, wired into `scripts/DiscreteSyms.jl` as:

* **option 5**: SIO, ECC setting (`T = t`, `X(t,x,p)`, `P(t,x,p)`), full chain rule,
  parameters and output included.
* **option 6**: same, but `T`, `X`, `P` may also depend on the inputs (`T` transformed).

Equations (`D(F) = F_t + sum_j F_x_j f_j + F_u u_t`):

    states     : f_i(T, X, u, P) * D(T) - D(X_i) = 0      (D(T) = 1 when T = t)
    parameters : D(P_k) = 0
    outputs    : h_l(X, u, P) - h_l(x, u, p) = 0

Splitting: always with respect to `u_t`; with respect to powers of `u` only when nothing depends
on `u` (option 5). In option 6, `u` is a coordinate and cannot be split.

Names of the unknowns are the same as in the rest of the repo (`X1`, `X1t`, `X1x2`, `X1u`,
`T`, `Tt`, `Tx1`, `Tu`, `P1`, `P1t`, `P1x2`, `u_t`), so the Maple side does not change.
Output: `equations_<name>_<tag>.txt` and `coefficients_<name>_<tag>.txt` in the working folder.

Old options 1–4 are unchanged (only a warning comment was added next to the affected lines).

## How to check it

1. Julia self-test: run `scripts/TestFiniteDetSys.jl`. Expected:
   * swap `p4 <-> p7`: all zeros in the three cases;
   * family `(a, g)`: all zeros only without input (with input: `[0, -a*u, g*u*(...), 0, ...]`);
   * time shift `T = t + c`: all zeros in the time-transform setting.
2. Python cross-check (same equations, same names): `python3 scripts/reference_detsys.py`.
   It writes `Results/reference_DAISY_EX3_*` files to compare with the Julia output.

Note: this code could not be executed in Julia when it was written (only the Python reference was
run). Please run the self-test first.

## Other things noticed (not changed)

* Infinitesimal code, `src/functions_conts.jl`: the prolongation keeps only the diagonal term,
  `epsi_x_syms[i]*variables.DS[i]` (lines 211 and 432), i.e. `xi_i,t + xi_i,x_i * dx_i` instead of
  `xi_i,t + sum_j xi_i,x_j * dx_j` (draft eq. (24a) / ECC eq. (9a) in components). The diagonal
  taken at line 143 is harmless, because that Jacobian (d g / d xdot) is the identity.
  Line 381 builds the parameter equation as `sum(zeta_t) + sum(zeta_x) * f_j`, mixing all
  parameters, instead of `zeta_k,t + sum_j zeta_k,x_j * f_j = 0` for each parameter `k` (eq. (26)).
* Draft (main.tex), eqs. (24a)-(24b): the terms `(xi_x - 1)` and `(zeta_theta - 1)` are wrong;
  with tau = 0, eq. (9) gives `xi_t + xi_x xdot + xi_theta thetadot` (fixed in the ECC version,
  eq. (9a)-(9b)). The code already removed this "-1" (commented block at line 422).
* `Models/Bilirubin2.jl` (and the copy in `Model.jl`): the equation of `x1` has an extra minus
  sign in front, `- (-(k21+k31+k41+k01)*x1 + ... + u)`, which is not in the ECC paper, eq. (13).
* The time-transform setting (option 6) admits the time shift `T = t + c` in every autonomous
  model, e.g. DAISY_EX3 with input, which is at least locally identifiable.
