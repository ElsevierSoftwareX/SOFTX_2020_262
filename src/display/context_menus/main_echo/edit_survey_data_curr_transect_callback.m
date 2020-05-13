function edit_survey_data_curr_transect_callback(~,~,main_figure)
layer=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');
[trans_obj,~]=layer.get_trans(curr_disp);
trans=trans_obj;

ids=unique(trans.Data.FileId);
if isempty(layer.SurveyData)
    surv=survey_data_cl();
else
    surv=layer.get_survey_data('Idx',1);
end
surv=edit_survey_data_fig(main_figure,surv,{'off' 'off' 'on' 'on' 'on' 'on' 'on'},'Transect');
if isempty(surv)>0
    return;
end

for idd=ids
    ifi=find(trans.Data.FileId==idd);
    
    start_time=trans.Time(ifi(1));
    end_time=trans.Time(ifi(end));
    
    surv.StartTime=start_time;
    surv.EndTime=end_time;
    
    surv.StartTime=start_time;
    surv.EndTime=end_time;
    layer_cl.empty.update_echo_logbook_dbfile('Filename',layer.Filename{idd},'SurveyData',surv,'main_figure',main_figure);
end
layer.load_echo_logbook_db();

update_tree_layer_tab(main_figure);
display_survdata_lines(main_figure);
load_logbook_tab_from_db(main_figure,1);

end