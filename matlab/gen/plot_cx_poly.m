function err= plot_cx_poly(cx_name, lambda_theta_cx, param)

coeff_name= [cx_name '_coeff'];
exp_name= [cx_name '_exp'];

poly_cx= zeros(size(lambda_theta_cx, 1), 1);
for i= 1:size(lambda_theta_cx, 1)
    poly_cx(i)= eval_poly(lambda_theta_cx(i, 1), lambda_theta_cx(i, 2), param.(coeff_name), param.(exp_name));
end


err= abs(poly_cx(:)-lambda_theta_cx(:, 3))./abs(lambda_theta_cx(:, 3));
err(err>1)= 1;

clf

scatter3(lambda_theta_cx(:, 1), lambda_theta_cx(:, 2), err*100, 4, log10(err), 'filled')
view(0, 90)
grid on

caxis([-3 0])
cbar = colorbar;
set(cbar,'YTickLabel',sprintfc('%5.1f%%', 10.^get(cbar,'YTick')*100));
 
ylabel('theta in °')
xlabel('lambda')