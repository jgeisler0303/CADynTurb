function ha_= plot_timeseries_multi(tscs, vars, names, t0, t1)

linetype_order= {'-', '--', '-.', ':'};
color_order= colororder;
if ~iscell(vars)
    vars= {vars};
end
if ~exist('names', 'var') || isempty(names)
    names= compose('data%d', 1:length(tscs));
end
if ~exist('t0', 'var')
    t0= inf;
    for i= 1:length(tscs)
        t0= min(tscs{i}.Time(1), t0);
    end
end
if ~exist('t1', 'var')
    t1= -inf;
    for i= 1:length(tscs)
        t1= max(tscs{i}.Time(end), t1);
    end
end

idx= cell(size(tscs));
for i= 1:length(tscs)
    idx{i}= tscs{i}.Time>=t0 & tscs{i}.Time<=t1;
end

clf
n_plots= length(vars);
for i_plot= 1:n_plots
    ha(i_plot)= subplot(n_plots, 1, i_plot);
    
    sub_vars= vars{i_plot};
    if ~iscell(sub_vars)
        sub_vars= {sub_vars};
    end
    
    n_lines= length(sub_vars);
    hold on
    label_str= '';
    for i_line= 1:n_lines
        for i_tsc= 1:length(tscs)
            plot_var= sub_vars{i_line};
            [plot_var, mod_str]= plot_var_mod(plot_var);

            ts= tscs{i_tsc}.get(plot_var);
            if ~isempty(ts)
                data= ts.Data(idx{i_tsc}, :);
                if ~isempty(mod_str)
                    data= eval(mod_str);
                end
                
                h= plot(ts.Time(idx{i_tsc}), data, 'DisplayName', [ts.Name ' (' names{i_tsc} ')']);
                set(h, 'Color', color_order(i_tsc, :));
                set(h, 'LineStyle', linetype_order{i_line});
                if isempty(label_str)
                    label_str= [ts.Name ' in ' ts.DataInfo.Units];
                end
            end
        end
    end    
    hold off
    
    if i_plot==n_plots
        xlabel('Time in s')
    end
    ylabel(label_str, 'Interpreter', 'none');
    legend('Location', 'SouthWest', 'NumColumns', n_lines, 'Interpreter', 'none')
    grid on
end

linkaxes(findobj(gcf, 'Type', 'Axes'), 'x')

if nargout>0
    ha_= ha;
end