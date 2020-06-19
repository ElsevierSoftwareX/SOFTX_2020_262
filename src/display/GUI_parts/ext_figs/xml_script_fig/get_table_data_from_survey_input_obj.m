function [data_init,log_files]=get_table_data_from_survey_input_obj(survey_input_obj,logbook_file)

log_files=cell(1,length(survey_input_obj.Snapshots));
for i=1:numel(log_files)
    log_files{i}= survey_input_obj.Snapshots{i}.Folder;
end

if ~iscell(logbook_file)
    log_add={logbook_file};
else
    log_add=logbook_file;
end

log_files=unique([log_files(:);log_add(:)]);

data_init=[];
idx_rem=[];
for i=1:numel(log_files)
    log_file=log_files{i};
    if isfile(log_file)||isfolder(log_file)
        db_conn=connect_to_db(log_file);
        if ~isempty(db_conn)
            sql_query='SELECT DISTINCT Snapshot,Type,Stratum,Transect,Comment FROM logbook';
            output_db=db_conn.fetch(sql_query);
            db_conn.close();
            if istable(output_db)
                data_init_tmp=table2cell(output_db);
            else
                data_init_tmp=output_db;
            end
            
            folder_cell=cell(size(data_init_tmp,1),1);
            if isfile(log_file)
                folder_cell(:)={fileparts(log_file)};
            else
                  folder_cell(:)={log_file};
            end
            data_init_tmp=[num2cell(false(size(data_init_tmp,1),1)) folder_cell data_init_tmp];
            data_init=[data_init;data_init_tmp];
        else
            idx_rem=union(idx_rem,i);
        end
    else
        idx_rem=union(idx_rem,i);
    end
end
log_files(idx_rem)=[];

[valid,~]=survey_input_obj.check_n_complete_input();

if valid
    [snaps,types,strat,trans_tot,~,~]=survey_input_obj.merge_survey_input_for_integration();
    for i=1:numel(snaps)

        switch types{i}
            case {' ',''}
                idx_true=find(trans_tot(i)==[data_init{:,6}]....
                    &snaps(i)==[data_init{:,3}]...
                    &strcmpi(deblank(strat{i}),deblank(data_init(:,5)))');
            otherwise
                idx_true=find(trans_tot(i)==[data_init{:,6}]....
                    &snaps(i)==[data_init{:,3}]...
                    &strcmpi(deblank(strat{i}),deblank(data_init(:,5)))'...
                    &contains(deblank(data_init(:,4)),deblank(strsplit(types{i},';')))');
        end
        data_init(idx_true,1)={true};
    end
end