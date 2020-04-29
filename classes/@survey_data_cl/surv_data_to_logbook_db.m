function surv_data_to_logbook_db(surv_data_obj,dbconn,filename,varargin)

p = inputParser;

addRequired(p,'surv_data_obj',@(x) isa(x,'survey_data_cl'));
addRequired(p,'dbconn',@(x) isa(x,'sqlite'));
addRequired(p,'filename',@ischar);
addParameter(p,'StartTime',0,@isnumeric);
addParameter(p,'EndTime',1,@isnumeric);
parse(p,surv_data_obj,dbconn,filename,varargin{:});
et_num=1e9;

if p.Results.StartTime==0
    if isfield(dbconn,'DataSource')
        [path_f,~,~]=fileparts(dbconn.DataSource);
    else
        [path_f,~,~]=fileparts(dbconn.Database);
    end
    [st_num,et_num,~]=start_end_time_from_file(fullfile(path_f,filename));
else
    st_num=p.Results.StartTime;   
end

st=datestr(st_num,'yyyy-mm-dd HH:MM:SS');

if p.Results.EndTime~=1
    et_num=p.Results.EndTime;
end

et=datestr(et_num,'yyyy-mm-dd HH:MM:SS');

strat=surv_data_obj.Stratum;
snap=surv_data_obj.Snapshot;
trans=surv_data_obj.Transect;
type=surv_data_obj.Type;
comm=surv_data_obj.Comment;

try
    
    createsurveyTable(dbconn);
    %survey_data=dbconn.fetch('select SurveyName, Voyage from survey');
    %     if all(cellfun(@isempty,survey_data))
    tz=dbconn.fetch(sprintf('SELECT Timezone FROM survey'));
    dbconn.exec('delete from survey');
    if iscell(tz)
        tz=tz{1};
    end
    
    if ~isempty(tz)
        dbconn.insert('survey',{'Voyage' 'SurveyName' 'Timezone'},...
            {surv_data_obj.Voyage surv_data_obj.SurveyName tz});
    else
        dbconn.insert('survey',{'Voyage' 'SurveyName'},...
            {surv_data_obj.Voyage surv_data_obj.SurveyName});
    end
    %end
    
    if ~isdeployed()
       fprintf('Insert Survey data for file %s Snap. %d Type %s Strat. %s Trans. %d StartTime %s EndTime %s\n',filename,snap,type,strat,trans,st,et); 
    end
%     t.Filename = filename;
%     t.Snapshot = snap;
%     t.Type = type;
%     t.Stratum = strat;
%     t.Transect = trans;
%     t.StartTime  = st;
%     t.EndTime = et;
%     t.Comment = comm;
%     
%     datainsert_perso(dbconn,'logbook',t);
    %dbconn.exec('DELETE FROM logbook WHERE Filename = "L0018-D20101203-T100444-ES60.raw"')
    dbconn.insert('logbook',{'Filename' 'Snapshot' 'Type' 'Stratum' 'Transect' 'StartTime' 'EndTime' 'Comment'},...
            {filename snap type strat trans st et comm});
        
        %     after_log=dbconn.fetch(sprintf('select * from logbook where Filename is "%s"',filename))
        %     after=dbconn.fetch('select * from survey')
catch err
    print_errors_and_warnings([],'error',err);
end

end