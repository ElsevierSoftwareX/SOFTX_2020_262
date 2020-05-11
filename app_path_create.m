function app_path=app_path_create()

app_path_fields  = {'data_root' 'cvs_root' 'data_temp' 'data'...
    'scripts' 'results' ...
    'test_folder'};

app_path_folders = {fullfile(whereisEcho,'example_data') ':local:Z:' fullfile(tempdir,'data_echo') fullfile(whereisEcho,'example_data','ek60') ...
    fullfile(whereisEcho,'echo_scripts') fullfile(whereisEcho,'echo_results') ...
    fullfile(whereisEcho,'example_data','ek60') fullfile(whereisEcho,'echo_scripts') fullfile(whereisEcho,'echo_results') fullfile(whereisEcho,'echo_results')};
app_path_descr = {'Root Data folder' 'CVS root folder' 'Temporary folder' 'Data folder'...
    'Script folder' 'Results folder' ...
    'Test folder'};
app_path_tstring  = {'Root Data folder' 'CVS root folder' 'Temporary folder' 'Data folder'...
    'Script folder' 'Results folder' ...
    'Test folder'};

if ~isdeployed()
    idx = 1:numel(app_path_fields);
else
    find(~ismember(app_path_fields,{'cvs_root' 'test_folder'}));
end

for ui=idx
    app_path.(app_path_fields{ui}) =  path_elt_cl(app_path_folders{ui},'Path_description',app_path_descr{ui},'Path_tooltipstring',app_path_tstring{ui},'Path_fieldname',app_path_fields{ui});
end

end