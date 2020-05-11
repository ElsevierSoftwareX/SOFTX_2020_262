    function val=mantissa2single(S)
V=S-'0';
frc = 1+sum(V(10:32).*2.^(-1:-1:-23));
pow = sum(V(2:9).*2.^(7:-1:0))-127;
sgn = (-1)^V(1);
val = sgn * frc * 2^pow;
end