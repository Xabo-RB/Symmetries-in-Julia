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
                 time_transform=False, input_dependence=False, transform_params=True,
                 transform_inputs=False, include_output=True):
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
    if transform_inputs:
        subsXP.update({uk: sp.Symbol(up(uk.name)) for uk in u})
    if transform_params:
        subsXP.update(dict(zip(p, P)))
    fX = [e.xreplace(subsXP) for e in fx]
    hX = [e.xreplace(subsXP) for e in hx]

    DT = D("T") if time_transform else sp.Integer(1)
    eqs = [sp.expand(fXi * DT - D(Xi.name)) for fXi, Xi in zip(fX, X)]
    if transform_params:
        eqs += [sp.expand(D(Pk.name)) for Pk in P]
    if include_output:
        eqs += [sp.expand(a - b) for a, b in zip(hX, hx)]
    return eqs, dict(x=x, p=p, u=u, ut=ut, X=X, P=P)


def build_infinitesimal(states, params, inputs, f, h,
                        time_transform=False, input_dependence=False, transform_params=True,
                        transform_inputs=False, include_output=True):
    """Linear (infinitesimal) determining system for V = tau d_t + xi.d_x + zeta.d_p + eta.d_u.
    Unknown names: tau, xi_x1, zeta_p1, eta_u and derivatives tau_t, xi_x1_x2, zeta_p1_t, xi_x1_u...
        states     : D(xi_i) - f_i D(tau) - V(f_i) = 0
        parameters : D(zeta_k) = 0
        outputs    : V(h_l) = 0
    with D(F) = F_t + sum_j F_{x_j} f_j + F_u u_t and V(g) = tau g_t + xi.g_x + zeta.g_p + eta.g_u."""
    t = sp.Symbol("t")
    x = [sp.Symbol(s) for s in states]
    p = [sp.Symbol(s) for s in params]
    u = [sp.Symbol(s) for s in inputs]
    ut = [sp.Symbol(s + "_t") for s in inputs]
    loc = {s.name: s for s in x + p + u}
    loc["t"] = t
    fx = [sp.sympify(e, locals=loc) for e in f]
    hx = [sp.sympify(e, locals=loc) for e in h]

    def D(F):
        expr = sp.Symbol(F + "_t") + sum(sp.Symbol(F + "_" + xj.name) * fj for xj, fj in zip(x, fx))
        if input_dependence:
            expr += sum(sp.Symbol(F + "_" + uk.name) * utk for uk, utk in zip(u, ut))
        return expr

    tau = sp.Symbol("tau") if time_transform else 0
    xi = [sp.Symbol("xi_" + s) for s in states]
    zeta = [sp.Symbol("zeta_" + s) for s in params] if transform_params else [0] * len(p)
    eta = [sp.Symbol("eta_" + s) for s in inputs] if transform_inputs else [0] * len(u)

    def V(g):
        return (tau * sp.diff(g, t) + sum(a * sp.diff(g, v) for a, v in zip(xi, x))
                + sum(a * sp.diff(g, v) for a, v in zip(zeta, p))
                + sum(a * sp.diff(g, v) for a, v in zip(eta, u)))

    DT = D("tau") if time_transform else 0
    eqs = [sp.expand(D("xi_" + s) - fi * DT - V(fi)) for s, fi in zip(states, fx)]
    if transform_params:
        eqs += [sp.expand(D("zeta_" + s)) for s in params]
    if include_output:
        eqs += [sp.expand(V(hl)) for hl in hx]
    return eqs, dict(x=x, p=p, u=u, ut=ut)


def residual_inf(eqs, syms, generator):
    """Plug an explicit generator {'tau': expr, 'xi_x1': expr, 'zeta_p1': expr, 'eta_u': expr}."""
    t = sp.Symbol("t")
    subs = {}
    for name, F in generator.items():
        subs[sp.Symbol(name)] = F
        subs[sp.Symbol(name + "_t")] = sp.diff(F, t)
        for v in syms["x"] + syms["u"]:
            subs[sp.Symbol(name + "_" + v.name)] = sp.diff(F, v)
    return [sp.simplify(e.xreplace(subs)) for e in eqs]


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


def _extra_tests():
    """Infinitesimal and new-flag checks (run with: python3 reference_detsys.py --extra)."""
    t, x1, x2, x, u, p1, p3, p4, p6, p7, a, g = sp.symbols("t x1 x2 x u p1 p3 p4 p6 p7 a g")
    states, params, h = ["x1", "x2", "x3"], ["p1", "p3", "p4", "p6", "p7"], ["x1"]
    f_in = ["-p1*x1 + x2 + u", "p3*x1 - p4*x2 + x3", "p6*x1 - p7*x3"]
    f_free = ["-p1*x1 + x2", "p3*x1 - p4*x2 + x3", "p6*x1 - p7*x3"]
    x3 = sp.Symbol("x3")
    # generators of the (a, g) family: derivatives at a = g = 0
    beta = g * (p4 - p7 + g); P4 = p4 + g - a
    fam = {"xi_x1": x1, "xi_x2": x2 + a*x1, "xi_x3": x3 + beta*x1 + g*x2, "zeta_p1": p1 + a,
           "zeta_p4": P4, "zeta_p7": p7 - g, "zeta_p3": p3 - a*p1 + a*P4 - beta,
           "zeta_p6": p6 - beta*p1 + g*p3 + (p7 - g)*beta}
    gen_a = {k: sp.diff(v, a).subs({a: 0, g: 0}) for k, v in fam.items()}
    gen_g = {k: sp.diff(v, g).subs({a: 0, g: 0}) for k, v in fam.items()}
    for label, f, inp in [("no input", f_free, []), ("with input", f_in, ["u"])]:
        eqs, syms = build_infinitesimal(states, params, inp, f, h)
        print(f"INF SI DAISY {label}: generator d/da ->", residual_inf(eqs, syms, gen_a),
              "| d/dg ->", residual_inf(eqs, syms, gen_g))
    # Nick's example (no output): Werner's document, Section 6 and Example 6.4
    fN = ["1 + u*x"]
    eqs, syms = build_infinitesimal(["x"], [], ["u"], fN, [], time_transform=True,
                                    input_dependence=True, transform_params=False, include_output=False)
    print("INF Nick, T and u: time translation      ->", residual_inf(eqs, syms, {"tau": 1, "xi_x": 0}))
    print("INF Nick, T and u: old exp(ut) d_x       ->", residual_inf(eqs, syms, {"tau": 0, "xi_x": sp.exp(u*t)}))
    eqs, syms = build_infinitesimal(["x"], [], ["u"], fN, [], time_transform=True, input_dependence=True,
                                    transform_params=False, transform_inputs=True, include_output=False)
    gen = {"tau": u*x, "xi_x": u*x + u**2*x**2/2, "eta_u": -(u**2 + u**3*x/2)}
    print("INF Nick, general (T, X, U), Werner Ex. 6.4 field with eta ->", residual_inf(eqs, syms, gen))
    gen_no_eta = {"tau": u*x, "xi_x": u*x + u**2*x**2/2, "eta_u": 0}
    print("INF Nick, general, same field without eta               ->", residual_inf(eqs, syms, gen_no_eta))
    # Observability (parameters fixed): x1' = p*x2, x2' = p*x1, y = x1 + x2, swap x1 <-> x2
    p = sp.Symbol("p")
    eqs, syms = build_detsys(["x1", "x2"], ["p"], [], ["p*x2", "p*x1"], ["x1 + x2"], transform_params=False)
    print("FIN Obs swap x1<->x2 ->", residual(eqs, syms, {"X1": x2, "X2": x1}))
    eqs, syms = build_infinitesimal(["x1", "x2"], ["p"], [], ["p*x2", "p*x1"], ["x1 + x2"], transform_params=False)
    # x1 - x2 is unobservable (y = x1 + x2 does not see it); it decays like exp(-p t)
    print("INF Obs generator exp(-p t)(d_x1 - d_x2) ->",
          residual_inf(eqs, syms, {"xi_x1": sp.exp(-p*t), "xi_x2": -sp.exp(-p*t)}))
    # General transformation (section 2) finite: time translation of Nick's example
    eqs, syms = build_detsys(["x"], [], ["u"], fN, [], time_transform=True, input_dependence=True,
                             transform_params=False, transform_inputs=True, include_output=False)
    print("FIN Nick, general (T, X, U), time translation ->",
          residual(eqs, syms, {"T": t + 1, "X": x, "U": u}))


if __name__ == "__main__" and "--extra" in __import__("sys").argv:
    _extra_tests()
