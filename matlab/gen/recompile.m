function do_compile= recompile(target, dependencies)

do_compile= false;
if exist(target, 'file')
    dd_dst= dir(target);
    for i= 1:length(dependencies)
        dd_src= dir(dependencies{i});
        if dd_src.datenum>dd_dst.datenum
            do_compile= false;
        end
    end
else
    do_compile= true;
end
