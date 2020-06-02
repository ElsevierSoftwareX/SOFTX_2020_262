function app_path=app_path_create()

app_path_fields  = {'data_root' 'cvs_root' 'data_temp' 'data'...
    'scripts' 'results' ...
    'test_folder'};
main_path = whereisEcho();

app_path_folders = {fullfile(main_path,'example_data') fullfile(tempdir,'data_echo') fullfile(main_path,'example_data','ek60') ...
    fullfile(main_path,'echo_scripts') fullfile(main_path,'echo_results') ...
    ':local:Z:' fullfile(main_path,'example_data','ek60')};

app_path_descr = {'Root Data folder' 'Temporary folder' 'Data folder'...
    'Script folder' 'Results folder' ...
    'CVS root folder' 'Test folder'};
app_path_tstring  = {'Root Data folder' 'Temporary folder' 'Data folder'...
    'Script folder' 'Results folder' ...
     'CVS root folder' 'Test folder'};


if isdeployed()
    idx = 1:numel(app_path_fields)-2;
else
    idx = 1:numel(app_path_fields);
end


for ui=idx
    app_path.(app_path_fields{ui}) =  path_elt_cl(app_path_folders{ui},'Path_description',app_path_descr{ui},'Path_tooltipstring',app_path_tstring{ui},'Path_fieldname',app_path_fields{ui});
end

end