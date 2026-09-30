restart:

f[1] := (k21 + k31 + k41 + k01)*x1(t) - k12*x2(t) - k13*x3(t) - k14*x4(t) - u;
f[2] := k21*x1(t) - k12*x2(t);
f[3] := k31*x1(t) - k13*x3(t);
f[4] := k41*x1(t) - k14*x4(t);
f[5] := x1(t);

difX := proc()
    diff(X(t,x(t)),t)
end proc;

for i to n do
    dX[i]:=difX()
end do;



