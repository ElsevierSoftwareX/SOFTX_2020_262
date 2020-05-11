function load_logbook_from_xml_callback(~,~,main_figure,path_init)

[xml_file,path_f]= uigetfile(fullfile(path_init,'*.csv;*.txt'), 'Choose csv file','MultiSelect','off');

if path_f==0
    return;
end


xml_logbook_to_db(fullfile(path_f,xml_file));
import_survey_data_callback([],[],main_figure);
tag=sprintf('logbook_%s',path_init);

dest_fig=getappdata(main_figure,'echo_tab_panel');

tag=sprintf('logbook_%s',path_init);
tab_obj=findobj(dest_fig,'Tag',tag);

if ~isempty(tab_obj)
    delete(tab_obj);
end
load_logbook_tab_from_db(main_figure,0,1,fullfile(path_init,'echo_logbook.db'));

end