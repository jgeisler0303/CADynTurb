function [plot_var, mod_str]= plot_var_mod(plot_var)
re= regexp(plot_var, '^([\w\d_]*)({.*})?$', 'tokens', 'once');
if isempty(re)
    warning('no valid variable name "%s"', plot_var);
    plot_var= 'unknown';
else
    plot_var= re{1};
end

if length(re)>1 && ~isempty(re{2})
    eq= strrep(strrep(re{2}, '{', ''), '}', '');
    if ~isempty(regexp(eq, '\<d\>', 'once'))
        mod_str= regexprep(eq, '\<d\>', 'data');
    else
        mod_str= ['data' eq];
    end
else
    mod_str= '';
end
