function surv_data=get_file_survey_data_from_db(filename,fst,fet)
surv_data={};

try
    [path_f,filename_s,end_file]=fileparts(filename);
    
    db_file=fullfile(path_f,'echo_logbook.db');
    if ~(exist(db_file,'file')==2)
        initialize_echo_logbook_dbfile(path_f,[],0)
    end
    dbconn=sqlite(db_file,'connect');
    survey_data=dbconn.fetch('SELECT SurveyName,Voyage from survey');
    if isempty(survey_data)
        survey_data={'' ''};
    end
    
    createlogbookTable(dbconn);
    
    try
        data_logbook=dbconn.fetch(sprintf('SELECT Snapshot,Stratum,Transect,StartTime,EndTime,Comment,Type FROM logbook WHERE Filename = "%s%s" ORDER BY StartTime',filename_s,end_file));
    catch
        data_logbook=dbconn.fetch(sprintf('SELECT Snapshot,Stratum,Transect,StartTime,EndTime,Comment FROM logbook WHERE Filename = "%s%s" ORDER BY StartTime',filename_s,end_file));
    end
    
    nb_surv_data=size(data_logbook,1);
    surv_data=cell(1,nb_surv_data);
    
    for i=1:nb_surv_data
        if size(data_logbook,2)>=7
            type=data_logbook{i,7};
        else
            type=' ';
        end
        
        surv_data{i}=survey_data_cl(...
            'Voyage',survey_data{2},...
            'SurveyName',survey_data{1},...
            'Snapshot',data_logbook{i,1},...
            'Type',type,...
            'Stratum',data_logbook{i,2},...
            'Transect',data_logbook{i,3},...
            'StartTime',datenum(data_logbook{i,4},'yyyy-mm-dd HH:MM:SS'),...
            'EndTime',datenum(data_logbook{i,5},'yyyy-mm-dd HH:MM:SS'),...
            'Comment',data_logbook{i,6});
    end
    
    if ~isempty(surv_data)
        st=surv_data{1}.StartTime;
        et=surv_data{end}.EndTime;
    end
    
    if abs(fet-et)>1/(24*60*60) && abs(st-fst)>1/(24*60*60)
        surv_data{1}.StartTime=fst;
        surv_data{end}.EndTime=fet;
        dbconn.exec(sprintf('UPDATE logbook SET StartTime = "%s",EndTime = "%s"   WHERE Filename = "%s%s" AND StartTime = "%s"',datestr(fst,'yyyy-mm-dd HH:MM:SS'),datestr(fet,'yyyy-mm-dd HH:MM:SS'),filename_s,end_file,data_logbook{i,4}))        
    elseif abs(st-fst)>1/(24*60*60)
        surv_data{1}.StartTime=fst;
        dbconn.exec(sprintf('UPDATE logbook SET StartTime = "%s"   WHERE Filename = "%s%s" AND StartTime = "%s"',datestr(fst,'yyyy-mm-dd HH:MM:SS'),filename_s,end_file,data_logbook{i,4}))  
    elseif abs(fet-et)>1/(24*60*60)
        surv_data{end}.EndTime=fet;
        dbconn.exec(sprintf('UPDATE logbook SET EndTime = "%s" WHERE Filename = "%s%s" AND EndTime = "%s"',datestr(fet,'yyyy-mm-dd HH:MM:SS'),filename_s,end_file,data_logbook{i,5}));
    end
     dbconn.close();
    
catch err
    print_errors_and_warnings([],'error',err);
end



end