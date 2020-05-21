function fname=generate_valid_filename(fstr)

idx = strfind(fstr,':');

if any(idx>2)
    fstr(idx(idx>2))='';
end

[path_f,f_name,ext]=fileparts(fstr);

f_name=regexprep(f_name,'\W','_');
f_name=strrep(f_name,'__','_');

fname=fullfile(path_f,[f_name ext]);


end