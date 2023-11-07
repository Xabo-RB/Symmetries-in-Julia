restart:

#CONTROL SYSTEM:
# dx = f(t,x,u)
# y  = h(t,x,u) 

#DEFINIR F POR EL USUARIO

# Defina el número de ecuaciones del sistema (states eqns + outputs)
nx := 4:
for i to nx do 
    x[i] := unapply(x[i], t);
end do 

#x1 := unapply(x1(t), t);#x2 := unapply(x2(t), t);#x3 := unapply(x3(t), t); #x4 := unapply(x4(t), t);

ny := 1:

nT := nx + ny: #nº total of eqns

#Parameters
np := 7:


# Inicializa cada f[i] como una función vacía
for i to nT do
    f[i] := unapply(0, t);  
end do;

f[1] = - (-(k21+k31+k41+k01)*x[1] + k12*x[2] + k13*x[3] + k14*x[4] + u);
f[2] = k21*x[1] - k12*x[2];
f[3] = k31*x[1] - k13*x[3];
f[4] = k41*x[1] - k14*x[4];
f[5] = x1[t]: 



# GENERAL CASE:
# dx/dt = f(t,x(t),u) 
# Variable transformation to: tt = T(t,x), xx = X(t,x) 
#Compute dX/dT:
#Xt := diff(X(t, x(t)), t):
#Tt := diff(T(t, x(t)), t):
#XT := Xt/Tt;


# Use a for loop to calculate the derivatives automatically
for i from 1 to nx do
    X[i] := makefunction(t,x[i])
    Xt[i] := diff(X(t, x[i]), t);
    Tt[i] := diff(T(t, x[i]), t);
end do;


for i from 1 to n do
    XT[i] := Xt(i)/Tt;
end do;

#Control system transformed:
# XT(t,x,dx) = f (T(t,x), X(t,x), u)
# h(x,u) = h (T(t,x), X(t,x), u)

# XT(t,x,dx) -> XT(t,x) al substituirla por la función del sistema inicial f(t,x,u)
XT := subs(diff(x(t), t) = f(t,x), XT);





