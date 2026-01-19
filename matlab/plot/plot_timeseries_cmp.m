function ha_= plot_timeseries_cmp(tsc1, tsc2, vars1, vars2, name1, name2, t0, t1, t_ofs1, t_ofs2, one_legend)

if ~iscell(vars1)
    vars1= {vars1};
end
if ~exist('vars2', 'var') || isempty(vars2)
    vars2= vars1;
end
if ~exist('name1', 'var') || isempty(name1)
    name1= inputname(1);
    if isempty(name1)
        name1= 'series 1';
    end
end
if ~exist('name2', 'var') || isempty(name2)
    name2= inputname(2);
    if isempty(name2)
        name2= 'series 2';
    end
end
if ~exist('t0', 'var')
    t0= min(tsc1.Time(1), tsc2.Time(1));
end
if ~exist('t1', 'var')
    t1= max(tsc1.Time(end), tsc2.Time(end));
end
if ~exist('t_ofs1', 'var')
    t_ofs1= 0;
end
if ~exist('t_ofs2', 'var')
    t_ofs2= 0;
end
if ~exist('one_legend', 'var')
    one_legend= true;
end

idx1= tsc1.Time>=t0 & tsc1.Time<=t1;
idx2= tsc2.Time>=t0 & tsc2.Time<=t1;

clf
n_plots= max([length(vars1) length(vars2)]);
tiledlayout(n_plots, 1)
ha= zeros(n_plots, 1);
for i_plot= 1:n_plots
    ha(i_plot)= nexttile;
    
    if i_plot<=length(vars1)
        sub_vars1= vars1{i_plot};
        if ~iscell(sub_vars1)
            sub_vars1= {sub_vars1};
        end
    else
        sub_vars1= {};
    end
    if i_plot<=length(vars2)
        sub_vars2= vars2{i_plot};
        if ~iscell(sub_vars2)
            sub_vars2= {sub_vars2};
        end
    else
        sub_vars2= {};
    end
    
    n_lines= max([length(sub_vars1) length(sub_vars2)]);
    hold on
    label_str= '';
    color= zeros(n_lines, 3);
    for i_line= 1:n_lines
        if i_line<=length(sub_vars1)
            plot_var= sub_vars1{i_line};
            [plot_var, mod_str]= plot_var_mod(plot_var);
            
            ts= tsc1.get(plot_var);
            if ~isempty(ts)
                data= ts.Data(idx1, :);
                if ~isempty(mod_str)
                    data= eval(mod_str);
                end
                h= plot(ts.Time(idx1)+t_ofs1, data, 'DisplayName', [ts.Name ' (' name1 ')']);
                color(i_line, :)= get(h, 'Color');
                if isempty(label_str)
                    label_str= [ts.Name ' in ' ts.DataInfo.Units];
                end
            end
        end
        
        if i_line<=length(sub_vars2)
            plot_var= sub_vars2{i_line};
            [plot_var, mod_str]= plot_var_mod(plot_var);
            
            ts= tsc2.get(plot_var);
            if ~isempty(ts)
                data= ts.Data(idx2, :);
                if ~isempty(mod_str)
                    data= eval(mod_str);
                end
                if ~all(color(i_line, :)==0)
                    color_= brighten(color(i_line, :), 0.8);
                    plot(ts.Time(idx2)+t_ofs2, data, 'DisplayName', [ts.Name ' (' name2 ')'], 'Color', color_);
                else
                    plot(ts.Time(idx2)+t_ofs2, data, 'DisplayName', [ts.Name ' (' name2 ')']);
                end
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
    if ~one_legend
        legend('Location', 'SouthWest', 'NumColumns', n_lines, 'Interpreter', 'none')
    end
    grid on
end
if one_legend
    lg= legend({name1, name2}, 'Orientation', 'horizontal', 'Interpreter', 'none');
    lg.Layout.Tile = 'South';
end

linkaxes(findobj(gcf, 'Type', 'Axes'), 'x')

if nargout>0
    ha_= ha;
end