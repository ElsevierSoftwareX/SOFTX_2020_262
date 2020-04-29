function complete_survey_input_cl_from_struct(survey_input_obj,data_struct,idx_struct,reg_integ_type,reg_integ_type_filt)

fields=fieldnames(data_struct);
if ~isempty(idx_struct)
for ifi=1:numel(fields)
    data_struct.(fields{ifi})= data_struct.(fields{ifi})(idx_struct);
end
if isempty(reg_integ_type)
    reg_integ_type='IDs';
end

if isempty(reg_integ_type)
    reg_integ_type_filt='';
end

data_struct.Type(cellfun(@isempty,data_struct.Type))={' '};
data_struct.Stratum(cellfun(@isempty,data_struct.Stratum))={' '};

[~,snapshots,types,path_f]=findgroups(data_struct.Snapshot,data_struct.Type,data_struct.Folder);


survey_input_obj.Snapshots={};
for isnap=1:length(snapshots)
    survey_input_obj.Snapshots{isnap}.Folder=path_f{isnap};
    survey_input_obj.Snapshots{isnap}.Number=snapshots(isnap);
    survey_input_obj.Snapshots{isnap}.Type={types{isnap}};
    survey_input_obj.Snapshots{isnap}.Cal=[];
    idx_snap=find(data_struct.Snapshot==snapshots(isnap)&strcmpi(data_struct.Type,types{isnap})&strcmpi(data_struct.Folder,path_f{isnap}));

    stratum=unique(data_struct.Stratum(idx_snap));
    survey_input_obj.Snapshots{isnap}.Stratum=cell(1,length(stratum));
    
    for istrat=1:length(stratum)
        idx_strat=idx_snap(strcmp(data_struct.Stratum(idx_snap),stratum{istrat}));
        survey_input_obj.Snapshots{isnap}.Stratum{istrat}.Name=stratum{istrat};
        survey_input_obj.Snapshots{isnap}.Stratum{istrat}.Design='';
        survey_input_obj.Snapshots{isnap}.Stratum{istrat}.Radius='';
        transects=unique(data_struct.Transect(idx_strat));
        survey_input_obj.Snapshots{isnap}.Stratum{istrat}.Transects=cell(1,length(transects));
        for itrans=1:length(transects)
            survey_input_obj.Snapshots{isnap}.Stratum{istrat}.Transects{itrans}.number=transects(itrans);
            survey_input_obj.Snapshots{isnap}.Stratum{istrat}.Transects{itrans}.Bottom=struct('ver',0);
            survey_input_obj.Snapshots{isnap}.Stratum{istrat}.Transects{itrans}.Regions{1}=struct('ver',0,reg_integ_type,reg_integ_type_filt);
            survey_input_obj.Snapshots{isnap}.Stratum{istrat}.Transects{itrans}.Cal=[];
            survey_input_obj.Snapshots{isnap}.Stratum{istrat}.Transects{itrans}.Cells={};
        end
    end
    
end


end