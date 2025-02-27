function val= eval_poly(lam, th, coeff, exp)
val= 0;
for i=1:length(coeff)
    val= val + coeff(i)*(lam^exp(i, 1) * th^exp(i, 2));
end
