function edit_survey_data_layer_callback(~,~,main_figure,IDs)

if isempty(IDs)
    layer=get_current_layer();
    IDs={layer.Unique_ID};
end

layers_t=get_esp3_prop('layers');


idx_tot=[];

for i=1:numel(IDs)    
    [idx,found]=find_layer_idx(layers_t,IDs{i});
    if found>0
        idx_tot=union(idx_tot,idx);        
    end       
end
if isempty(idx_tot)
    return;
end
mod=0;
layers=reorder_layers_time(layers_t(idx_tot));
layers_Str_comp=list_layers(layers);

for i=1:numel(layers)
            
        layer=layers(i);
               
        trans=layer.Transceivers(1);
        start_time=trans.Time(1);
        end_time=trans.Time(end);
        
        if isempty(layer.SurveyData)
            surv=survey_data_cl();
        else
            surv=layer.get_survey_data('Idx',1);
        end
        
        surv.StartTime=start_time;
        surv.EndTime=end_time;
        tt=layers_Str_comp{i};
        surv=edit_survey_data_fig(main_figure,surv,{'off' 'off' 'on' 'on' 'on' 'on' 'on'},tt);
        if isempty(surv)>0
            continue;
        end
        mod=1;
        surv.StartTime=start_time;
        surv.EndTime=end_time;
        
        layer.set_survey_data(surv);
        layer.update_echo_logbook_dbfile('main_figure',main_figure);        
        load_logbook_tab_from_db(main_figure,'reload',1,'new_logbook',0,'layer',layer);
end

if mod>0
    import_survey_data_callback([],[],main_figure);   
end


end