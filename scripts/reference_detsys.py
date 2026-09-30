"""
Reference implementation (SymPy) of the finite determining system for SIO symmetries.

It builds the equations with the FULL chain rule (all cross derivatives), so it can be used
to cross-check the Julia code. Naming of the unknowns follows the Julia repo:
    X1, X1t, X1x2, X1u, T, Tt, Tx1, Tu, P1, P1t, P1x2, P1u, u_t

Unknown functions (all may depend on t, x, p and, optionally, u):
    T   : transformed time          (only if time_transform=True, otherwise T = t)
    X_i : transformed states
    P_k : transformed parameters    (only if transform_params=True, otherwise P = p)

Total derivative along solutions:  D(F) = F_t + sum_j F_{x_j} f_j(x,u,p) + F_u * u_t
(parameter derivatives F_p do not appear because dp/dt = 0).

Equations:
    states     : f_i(X, u, P) * D(T) - D(X_i) = 0     (D(T) = 1 if T = t)
    parameters : D(P_k) = 0
    outputs    : h_l(X, u, P) - h_l(x, u, p) = 0
Splitting: always w.r.t. u_t; also w.r.t. powers of u ONLY when nothing depends on u.
"""
import sympy as sp


def build_detsys(states, params, inputs, f, h,
                 time_transform=False, input_dependence=False, transform_params=True):
    t = sp.Symbol("t")
    x = [sp.Symbol(s) for s in states]
    p = [sp.Symbol(s) for s in params]
    u = [sp.Symbol(s) for s in inputs]
    ut = [sp.Symbol(s + "_t") for s in inputs]
    loc = {s.name: s for s in x + p + u}
    loc["t"] = t
    fx = [sp.sympify(e, locals=loc) for e in f]
    hx = [sp.sympify(e, locals=loc) for e in h]

    def up(name):  # name of the transformed object, as in the Julia repo
        return name.upper() if name != name.upper() else name + "_T"

    X = [sp.Symbol(up(s)) for s in states]
    P = [sp.Symbol(up(s)) for s in params] if transform_params else p

    def D(F):  # total derivative of the unknown function F (given by its name)
        expr = sp.Symbol(F + "t")
        expr += sum(sp.Symbol(F + xj.name) * fj for xj, fj in zip(x, fx))
        if input_dependence:
            expr += sum(sp.Symbol(F + uk.name) * utk for uk, utk in zip(u, ut))
        return expr

    subsXP = dict(zip(x, X))
    if time_transform:
        subsXP[t] = sp.Symbol("T")
    if transform_params:
        subsXP.update(dict(zip(p, P)))
    fX = [e.xreplace(subsXP) for e in fx]
    hX = [e.xreplace(subsXP) for e in hx]

    DT = D("T") if time_transform else sp.Integer(1)
    eqs = [sp.expand(fXi * DT - D(Xi.name)) for fXi, Xi in zip(fX, X)]
    if transform_params:
        eqs += [sp.expand(D(Pk.name)) for Pk in P]
    eqs += [sp.expand(a - b) for a, b in zip(hX, hx)]
    return eqs, dict(x=x, p=p, u=u, ut=ut, X=X, P=P)


def split(eqs, syms, input_dependence):
    """Coefficients that must vanish (split w.r.t. u_t, and w.r.t. u if allowed)."""
    gens = list(syms["ut"]) + ([] if input_dependence else list(syms["u"]))
    out = []
    for e in eqs:
        if gens:
            out += [c for c in sp.Poly(e, *gens).coeffs() if c != 0]
        elif e != 0:
            out.append(e)
    return out


def residual(eqs, syms, transformation, time_transform=False):
    """Plug an explicit transformation {'X1': expr, ..., 'P1': expr, 'T': expr} into the
    equations (with its true derivatives) and return the simplified residuals."""
    t = sp.Symbol("t")
    x, u = syms["x"], syms["u"]
    subs = {}
    for name, F in transformation.items():
        subs[sp.Symbol(name)] = F
        subs[sp.Symbol(name + "t")] = sp.diff(F, t)
        for v in x + u:
            subs[sp.Symbol(name + v.name)] = sp.diff(F, v)
    return [sp.simplify(e.xreplace(subs)) for e in eqs]


if __name__ == "__main__":
    import os
    outdir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "Results")
    states = ["x1", "x2", "x3"]
    params = ["p1", "p3", "p4", "p6", "p7"]
    f_in = ["-p1*x1 + x2 + u", "p3*x1 - p4*x2 + x3", "p6*x1 - p7*x3"]
    f_free = ["-p1*x1 + x2", "p3*x1 - p4*x2 + x3", "p6*x1 - p7*x3"]
    h = ["x1"]
    t, c = sp.symbols("t c")
    p1, p3, p4, p6, p7, x1, x2, x3, a, g = sp.symbols("p1 p3 p4 p6 p7 x1 x2 x3 a g")

    # Known symmetries (derived by hand)
    beta = g * (p4 - p7 + g)
    P4 = p4 + g - a
    family = {"X1": x1, "X2": x2 + a * x1, "X3": x3 + beta * x1 + g * x2,
              "P1": p1 + a, "P4": P4, "P7": p7 - g,
              "P3": p3 - a * p1 + a * P4 - beta,
              "P6": p6 - beta * p1 + g * p3 + (p7 - g) * beta}
    swap = {k: sp.simplify(v.subs({a: 0, g: p7 - p4})) for k, v in family.items()}
    translation = {"T": t + c, "X1": x1, "X2": x2, "X3": x3,
                   "P1": p1, "P3": p3, "P4": p4, "P6": p6, "P7": p7}

    cases = [("DAISY_EX3_input_ECC", f_in, ["u"], False, False),
             ("DAISY_EX3_noinput_ECC", f_free, [], False, False),
             ("DAISY_EX3_input_time_and_u", f_in, ["u"], True, True)]
    for tag, f, inp, tt, ud in cases:
        eqs, syms = build_detsys(states, params, inp, f, h,
                                 time_transform=tt, input_dependence=ud)
        coeffs = split(eqs, syms, ud)
        with open(os.path.join(outdir, f"reference_{tag}_equations.txt"), "w") as fh:
            fh.write("\n".join(str(e) for e in eqs) + "\n")
        with open(os.path.join(outdir, f"reference_{tag}_coefficients.txt"), "w") as fh:
            fh.write("\n".join(str(e) for e in coeffs) + "\n")
        print(f"\n===== {tag}: {len(eqs)} equations, {len(coeffs)} coefficients after splitting")
        fam, sw = (dict(family, T=t), dict(swap, T=t)) if tt else (family, swap)
        print("  family (a, gamma):", residual(eqs, syms, fam))
        print("  swap p4<->p7     :", residual(eqs, syms, sw))
        if tt:
            print("  time translation :", residual(eqs, syms, translation))
