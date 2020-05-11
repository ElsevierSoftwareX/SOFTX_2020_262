function surv_data_struct=import_survey_data_csv(FileN,Voyage,SurveyName)
surv_data_struct=[];

if exist(FileN,'file')==2
    
    surv_data_table=readtable(FileN);
    surv_data_struct=table2struct(surv_data_table,'ToScalar',true);
    %{'Voyage' 'SurveyName' 'Filename' 'Snapshot' 'Stratum' 'Transect' 'StartTime' 'Comment' 'EndTime'}
    if any(~isfield(surv_data_struct,{'File' 'Snapshot' 'Stratum' 'Transect'}))&&any(~isfield(surv_data_struct,{'Filename' 'Snapshot' 'Stratum' 'Transect'}))
        surv_data_struct=[];
        warndlg_perso([],'','Cannot find required fields in the *.csv file...');
        return;
    end
    
    if isfield(surv_data_struct,'File')
        surv_data_struct.Filename=surv_data_struct.File;
    else
        surv_data_struct.File=surv_data_struct.Filename;
    end
    
    if ~iscell(surv_data_struct.Stratum)
        idx_nan=isnan(surv_data_struct.Stratum);
        surv_data_struct.Stratum=replace_vec_per_cell(surv_data_struct.Stratum);
        surv_data_struct.Stratum(idx_nan)={''};
    end
    
    
    surv_data_struct.SurvDataObj=cell(1,length(surv_data_struct.Stratum));
    surv_data_struct.Voyage=cell(1,length(surv_data_struct.Stratum));
    surv_data_struct.Voyage(:)={Voyage};
    
    surv_data_struct.SurveyName=cell(1,length(surv_data_struct.Stratum));
    surv_data_struct.SurveyName(:)={SurveyName};
    if ~isfield(surv_data_struct,'Comment')
        surv_data_struct.Comment=cell(1,length(surv_data_struct.Stratum));
        surv_data_struct.Comment(:)={''};
    end
    if ~isfield(surv_data_struct,'StartTime')
        surv_data_struct.StartTime=zeros(1,length(surv_data_struct.Stratum));
        surv_data_struct.EndTime=ones(1,length(surv_data_struct.Stratum));
    else
       surv_data_struct.StartTime= datenum(surv_data_struct.StartTime) ;
       surv_data_struct.EndTime= datenum(surv_data_struct.EndTime) ;
    end
    
     if ~isfield(surv_data_struct,'Type')
         surv_data_struct.Type=cell(1,length(surv_data_struct.Stratum));
         surv_data_struct.Type(:)={' '};
     end
    
    for i=1:length(surv_data_struct.Stratum)
        t=surv_data_struct.Type{i};
        if isnan(t)
            t='';
        end
        s=surv_data_struct.Stratum{i};
        if isnan(s)
            s='';
        end
        surv_data_struct.SurvDataObj{i}=survey_data_cl(...
            'Voyage',surv_data_struct.Voyage{i},...
            'SurveyName',surv_data_struct.SurveyName{i},...
            'Snapshot',surv_data_struct.Snapshot(i),...
            'Type',t,...
            'Stratum',s,...
            'Transect',surv_data_struct.Transect(i),...
            'Comment',surv_data_struct.Comment{i},...
            'StartTime', surv_data_struct.StartTime(i),...
            'EndTime',surv_data_struct.EndTime(i));
        
    end
    
end
