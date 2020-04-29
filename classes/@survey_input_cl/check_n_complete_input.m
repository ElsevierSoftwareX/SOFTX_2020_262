function [valid,files_to_load]=check_n_complete_input(surv_input_obj,varargin)

esp3_obj=getappdata(groot,'esp3_obj');

if ~isempty(esp3_obj)
    app_path=get_esp3_prop('app_path');
    data_root_def=app_path.data_root;
else
   data_root_def=''; 
end

p = inputParser;

addRequired(p,'surv_input_obj',@(obj) isa(obj,'survey_input_cl'));
addParameter(p,'data_root',data_root_def,@(x) isempty(x)||isfolder(x));

parse(p,surv_input_obj,varargin{:});

infos=surv_input_obj.Infos;
% options=surv_input_obj.Options;
% regions_wc=surv_input_obj.Regions_WC;
% algos=surv_input_obj.Algos;
% cal=surv_input_obj.Cal;

surveyName=infos.SurveyName;
voyage=infos.Voyage;


snapshots=surv_input_obj.Snapshots;

valid=1;

fprintf('\n\nChecking survey input for %s  Voyage %s:\n',...
    surveyName,voyage);
files_to_load={};

nb_trans=0;

for isn=1:length(snapshots)
    
    if ~isfield(snapshots{isn},'Number')
        fprintf('Snapshot Number needs to be specified for %s\n',surveyName);
        valid=0;
        continue;
    end
    
    if ~isfield(snapshots{isn},'Folder')
        fprintf('Snapshot Folder needs to be specified for %s\n',surveyName);
        valid=0;
        return;
    end
    
    snap_num=snapshots{isn}.Number;
    snap_type=snapshots{isn}.Type;

    if ~iscell(snap_type)
        snap_type={snap_type};
    end
    
    if ~isfield(snapshots{isn},'Stratum')
        fprintf('No stratum for %s Snapshot %.0f\n',surveyName,snap_num);
        continue;
    end
    
    stratum=snapshots{isn}.Stratum;
    
        
    if ~isfolder(snapshots{isn}.Folder) && isfolder (fullfile(p.Results.data_root,snapshots{isn}.Folder))
        snapshots{isn}.Folder = fullfile(p.Results.data_root,snapshots{isn}.Folder);
    elseif ~isfolder(snapshots{isn}.Folder)
        fprintf('Cannot find folder %s \n',snapshots{isn}.Folder);
        valid=0;
        continue;
    end
    
    db_filename=fullfile(snapshots{isn}.Folder,'echo_logbook.db');
    
    if ~isfile(db_filename)
        fprintf('No logbook in for %s \n',snapshots{isn}.Folder);
        valid=0;
        continue;
    end
    
    fprintf('\nLooking in folder %s\n',snapshots{isn}.Folder);
    dbconn=sqlite(db_filename,'connect');   
    for ist=1:length(stratum)
        
        if ~isfield(stratum{ist},'Name')
            fprintf('Stratum Name needs to be specified for %s Snapshot %.0f\n',surveyName,snap_num);
            valid=0;
            continue;
        end
        strat_name=stratum{ist}.Name;
        
        if ~isfield(stratum{ist},'Transects')
            fprintf('No transects for %s Snapshot %.0f Stratum %s\n',surveyName,snap_num,stratum{ist}.Name);
            valid=0;
            continue;
        end
        
        transects=stratum{ist}.Transects;
        
        
        for itr=1:length(transects)
            
            if ~isfield(transects{itr},'number')
                fprintf('Transect number needs to be specified for %s Snapshot %.0f Stratum %s\n',surveyName,snap_num,strat_name);
                valid=0;
                continue;
            end
            trans_num=transects{itr}.number;
            
            if ~isfield(transects{itr},'files') 
                filenames={};
                for uit=1:numel(trans_num)
                    filenames_tmp={};
                    
                    for itype=1:length(snap_type)
                        nb_trans=nb_trans+1;
                        surv_temp=survey_data_cl('Voyage',voyage,...,...
                            'SurveyName',surveyName,...
                            'Type',snap_type{itype},...
                            'Snapshot',snap_num,...
                            'Stratum',strat_name,...
                            'Transect',trans_num(uit));
                        filenames_tmp_tmp=get_files_from_db(dbconn,surv_temp);
                        if istable(filenames_tmp_tmp)
                            filenames_tmp_tmp={filenames_tmp_tmp.Filename(:)};
                        end
                        filenames_tmp=union(filenames_tmp,filenames_tmp_tmp);
                    end
                    
                    if ~isempty(filenames_tmp(:))
                        fprintf(' Files added to Snapshot %.0f  Type %s Stratum %s Transect %.0f:\n',...
                            snap_num,strjoin(snap_type,' and '),strat_name,trans_num(uit));
                        fprintf('%s \n',filenames_tmp{:}); 
                    else
                        fprintf('!!!!!!!!!!!!No Files found in Snapshot %.0f Type %s Stratum %s Transect %.0f:\n',...
                            snap_num,strjoin(snap_type,' and '),strat_name,trans_num(uit));
                        valid=0;
                    end
                    filenames=union(filenames,filenames_tmp);
                end
                surv_input_obj.Snapshots{isn}.Stratum{ist}.Transects{itr}.files=filenames;
                files_to_load=union(files_to_load,filenames);
            else
                files_to_load=union(files_to_load,surv_input_obj.Snapshots{isn}.Stratum{ist}.Transects{itr}.files{:});
            end
        end
        
    end
    close(dbconn);
end

if valid==0
    fprintf('Invalid XML script file for Voyage %s %s\n',voyage,surveyName);
else
     fprintf('XML script file for Voyage %s %s appears to be valid, with %d transects over %d files\n',voyage,surveyName,nb_trans,numel(files_to_load));
end

end





