function filenames=get_files_from_db(dbconn,surv_data_obj)

p = inputParser;
addRequired(p,'dbconn',@(obj) isa(obj,'sqlite')||isa(dbconn,'database.jdbc.connection'));
addRequired(p,'surv_data_obj',@(obj) isa(obj,'survey_data_cl'));
parse(p,dbconn,surv_data_obj);

sql_cmd='select Filename from logbook where';
att={'Snapshot' 'Stratum' 'Type' 'Transect'};

u=0;
for iatt=1:numel(att)
    u=1;
    if ~isempty(surv_data_obj.(att{iatt}))
        if ischar(surv_data_obj.(att{iatt}))
            if ~isempty(deblank(surv_data_obj.(att{iatt})))
                sql_cmd=[sql_cmd sprintf(' %s is "%s" and',att{iatt},surv_data_obj.(att{iatt}))];
            end
        else
            if surv_data_obj.(att{iatt})~=0
                sql_cmd=[sql_cmd sprintf(' %s = %d and',att{iatt},surv_data_obj.(att{iatt}))];
            end
        end
    end
end

if u>0
    sql_cmd(end-3:end)=[];
else
    sql_cmd(end-6:end)=[];
end

filenames=dbconn.fetch(sql_cmd);


end