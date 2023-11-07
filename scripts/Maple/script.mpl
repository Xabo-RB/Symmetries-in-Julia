#restart:
nx := 4:
ny := 1:
f := Array(1..5);
Xt := Array(1..4);
Tt := Array(1..4);
F := Array(1..4);

f[1] := - (-(k21+k31+k41+k01)*x1(t) + k12*x2(t) + k13*x3(t) + k14*x4(t) + u);
f[2] := k21*x1(t) - k12*x2(t);
f[3] := k31*x1(t) - k13*x3(t);
f[4] := k41*x1(t) - k14*x4(t);
f[5] := x1(t);

Xt[1] := diff(X1(t, x1(t)),t);
Tt[1] := diff(T(t, x1(t)),t);

Xt[2] := diff(X2(t, x2(t)),t);
Tt[2] := diff(T(t, x2(t)),t);

Xt[3] := diff(X3(t, x3(t)),t);
Tt[3] := diff(T(t, x3(t)),t);

Xt[4] := diff(X4(t, x4(t)),t);
Tt[4] := diff(T(t, x4(t)),t);

for i from 1 to nx do
    F[i] := subs(x1(t) = X1(x1,t),x2(t) = X2(x2,t),x3(t) = X3(x3,t),x4(t) = X4(x4,t), f[i]):
end do:
