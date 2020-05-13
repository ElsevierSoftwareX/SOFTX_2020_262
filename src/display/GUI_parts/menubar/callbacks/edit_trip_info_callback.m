function edit_trip_info_callback(~,~,main_figure)

layer=get_current_layer();
layers=get_esp3_prop('layers');

if isempty(layer)
    return;
end

surveydata=layer.get_survey_data();

survey_data_out=edit_survey_data_fig(main_figure,surveydata,{'on' 'on' 'off' 'off' 'off' 'off' 'off'},'Voyage');

if isempty(survey_data_out)
    return;
end

[path_lay,~]=get_path_files(layer);
path_lay=unique(path_lay);

for up=1:numel(path_lay)
    path_f=path_lay{up};
    
    db_file=fullfile(path_f,'echo_logbook.db');
    if ~(exist(db_file,'file')==2)
        initialize_echo_logbook_dbfile(path_f,main_figure,0)
    end
    
    %surv_data_struct=import_survey_data_db(db_file);
    
    hfigs=getappdata(main_figure,'ExternalFigures');
    hfigs(~isvalid(hfigs))=[];
    
    if ~isempty(hfigs)
        tag=sprintf('logbook_%s',path_f);
        idx_tag=find(strcmpi({hfigs(:).Tag},tag));
        if~isempty(idx_tag)
            set(hfigs(idx_tag(1)),'Name',sprintf('%s',Voyage));
        end
    end
    
    path_lay=layer.get_path_files();
    [path_lays,ids]=layers.list_files_layers();
    
    path_lays=cellfun(@fileparts,path_lays,'un',0);
    
    idx_up=contains(path_lays,path_f);
    
    ids=ids(idx_up);
    idx_lay_up=[];
    for i=1:numel(ids)
        [tmp,fnd]=layers.find_layer_idx(ids{i});
        if fnd
            idx_lay_up=union(idx_lay_up,tmp);
        end
    end
    
    layers(idx_lay_up).update_echo_logbook_dbfile('SurveyName',survey_data_out.SurveyName,'Voyage',survey_data_out.Voyage,'main_figure',main_figure);
end


update_tree_layer_tab(main_figure);
load_info_panel(main_figure);
update_axis(main_figure,1,'main_or_mini','mini');

load_logbook_tab_from_db(main_figure,1);

end