function export_metadata_to_html_callback(~,~,main_figure,path_f)

if isempty(path_f)
    layer = get_current_layer();
    
    if isempty(layer)
        return;
    end
    [path_lay,~] = layer.get_path_files();
    path_f=path_lay{1};    
end

surv_data_struct = get_struct_from_db(path_f);
surv_data_table=struct2table(surv_data_struct);

uid=find(~(surv_data_table.Snapshot==0 & strcmpi(surv_data_table.Type,' ') & strcmpi(surv_data_table.Stratum,' ') & surv_data_table.Transect==0));


cols=cell(1,size(surv_data_table,1)+1);
cols{1}='#FE0000';

    cols(uid+1)={'#ADE6AB'};


filename=[surv_data_struct.Voyage{1} '_' surv_data_struct.SurveyName{1} '_logbook.html'];

ColHeads={'Filename' 'Snapshot' 'Type' 'Stratum' 'Transect' 'Comment' 'StartTime' 'EndTime'};
cols(cellfun(@isempty,cols))={'#E6ABB9'};

html_table([ColHeads;table2cell(surv_data_table(:,ColHeads))], fullfile(path_f,filename),...
    'DataFormatStr','%.0f',...
    'FirstRowIsHeading',1,...
    'RowBGColour',cols,...
    'Caption',sprintf('Voyage: %s Survey: %s',surv_data_struct.Voyage{1},surv_data_struct.SurveyName{1}),...
    'Title',sprintf('Voyage: %s Survey: %s',surv_data_struct.Voyage{1},surv_data_struct.SurveyName{1}));
    
    web(fullfile(path_f,filename),'-browser');
    
end