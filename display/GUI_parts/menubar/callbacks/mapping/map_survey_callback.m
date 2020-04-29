function map_survey_callback(~,~,hObject_main)

app_path=get_esp3_prop('app_path');

[Filename,PathToFile]= uigetfile( {fullfile(app_path.results)}, 'Pick a survey output file','MultiSelect','on');

if ~isequal(Filename, 0)
    
    if ~iscell(Filename)
        Filename = {Filename};
    end
    
    Filenames=cellfun(@(x) fullfile(PathToFile,x),Filename,'un',0);
    try
        obj_vec=load_surv_obj_frome_result_files(Filenames);
    catch err
        print_errors_and_warnings([],'error',err);
        disp_perso(hObject_main,'Could not load survey result file');
        return;
    end
    if ~isempty(obj_vec)
        load_map_fig(hObject_main,obj_vec);
    else
        return;
    end
    
else
    
    return;
    
end

end