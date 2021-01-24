function plot_timeseries(ts_collection, vars)

if ~iscell(vars)
    vars= {vars};
end

clf
n_plots= length(vars);
for i_plot= 1:n_plots
    subplot(n_plots, 1, i_plot)
    
    sub_vars= vars{i_plot};
    if ~iscell(sub_vars)
        sub_vars= {sub_vars};
    end
    
    n_lines= length(sub_vars);
    hold on
    label_str= '';
    for i_line= 1:n_lines
        plot_var= sub_vars{i_line};
        [plot_var, mod_str]= plot_var_mod(plot_var);
            
        ts= ts_collection.get(plot_var);
        if isempty(ts), continue, end
        
        data= ts.Data;
        if ~isempty(mod_str)
            data= eval(mod_str);
        end
        plot(ts.Time, data, 'DisplayName', ts.Name);
        if isempty(label_str)
            label_str= [ts.Name ' in ' ts.DataInfo.Units];
        end
    end
    hold off
    
    xlabel('Time in s')
    ylabel(label_str, 'Interpreter', 'none');
    legend('Location', 'SouthWest', 'Orientation', 'horizontal', 'Interpreter', 'none')
    grid on
end

linkaxes(findobj(gcf, 'Type', 'Axes'), 'x')
xlim([ts_collection.Time(1) ts_collection.Time(end)])
