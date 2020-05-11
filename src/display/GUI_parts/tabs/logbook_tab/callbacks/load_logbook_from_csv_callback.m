function load_logbook_from_csv_callback(~,~,main_figure,path_init)

[csv_file,path_f]= uigetfile(fullfile(path_init,'*.csv;*.txt'), 'Choose csv_file','MultiSelect','off');

if path_f==0
    return;
end


[Voyage,SurveyName,~,~,~,can]=fill_survey_data_dlbox([],'Voyage_only',1,'Title','Set Voyage Info');

if can>0
    return;
end

csv_logbook_to_db(path_init,fullfile(path_f,csv_file),Voyage,SurveyName);
import_survey_data_callback([],[],main_figure);

dest_fig=getappdata(main_figure,'echo_tab_panel');

tag=sprintf('logbook_%s',path_init);
tab_obj=findobj(dest_fig,'Tag',tag);

if ~isempty(tab_obj)
    delete(tab_obj);
end
load_logbook_tab_from_db(main_figure,0,1,fullfile(path_init,'echo_logbook.db'));

end