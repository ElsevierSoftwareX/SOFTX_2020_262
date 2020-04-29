function survey_obj = load_mbs_results_v2(filename)

survey_obj=[];

[fid, message] = fopen(filename);

if fid == -1
    disp(message)
    return
end
survey_obj=survey_cl();
% read in the first 14 lines - these contain various header bits.
line = fgetl(fid);
while ~contains(line,'#')
    [t,r]=strtok(line, ':');
    if strcmp(t,'number_of_regions')
        header.num_regions = str2double(r(3:length(r)));
    end
    if strcmp(t,'number_of_transects')
        header.num_transects = str2double(r(3:length(r)));
    end
    if strcmp(t,'title')
        survey_obj.SurvInput.Infos.Title = r(3:length(r));
    end
    if strcmp(t,'voyage')
        survey_obj.SurvInput.Infos.Voyage = r(3:length(r));
    end
    if strcmp(t,'author')
        survey_obj.SurvInput.Infos.Author = r(3:length(r));
    end
    if strcmp(t,'main_species')
        survey_obj.SurvInput.Infos.Main_species = r(3:length(r));
    end
    if strcmp(t,'areas')
        survey_obj.SurvInput.Infos.Areas = r(3:length(r));
    end
    if strcmp(t,'created')
        survey_obj.SurvInput.Infos.Created = r(3:length(r));
    end
    if strcmp(t,'comments')
        survey_obj.SurvInput.Infos.Comments = r(3:length(r));
    end
    if strcmp(t,'mbs_revision')
        header.mbs_revision = r(3:length(r));
    end
    if strcmp(t,'mbs_filename')
        header.MbsId = r(3:length(r));
    end
    if strcmp(t,'number_of_strata')
        header.num_strata = str2double(r(3:length(r)));
    end
    if strcmp(t,'number_of_transects')
        header.num_transects = str2double(r(3:length(r)));
    end
    line = fgetl(fid);
    
end

%header

surv_out_obj=survey_output_cl(header.num_strata, header.num_transects,header.num_regions);

% now find the section we want and read it in.
% At the moment we are only interested in the vertical abscf region summary

line = fgetl(fid);

while ~feof(fid)
    field='';
    if contains(line, '# Region Summary (abscf by vertical slice)')
        field='regionSumAbscf';
    elseif contains(line, '# Sliced Transect Summary')
        field='slicedTransectSum';
    elseif contains(line, '# Region vbscf')
        field='regionSumVbscf';
    elseif contains(line, '# Stratum Summary')
        field='stratumSum';
    elseif contains(line, '# Transect Summary')
        field='transectSum';
    elseif contains(line, '# Region Summary')
        field='regionSum';    
    end
    if~isempty(field)
        data_in=surv_out_obj.(field);
        tmp=read_mbs_data_block(fid,data_in);
        if ~isempty(tmp)
            surv_out_obj.(field) = tmp;
        end
    end
    line = fgetl(fid);
end

fclose(fid);
survey_obj.SurvOutput=surv_out_obj;
end

function data = read_mbs_data_block(fid,data_in)
data=data_in;

line = fgetl(fid);
idx_acc_s=strfind(line,'{');
idx_acc_e=strfind(line,'}');
if  isempty(idx_acc_s)
    fields=strsplit(line(2:end),' ');
    fields_vec={};
else
    fields=strsplit(line(2:idx_acc_s-1),' ');
    fields_vec=strsplit(line(idx_acc_s+1:idx_acc_e-1),' ');
end

if ismember('vbscf_values',fields)
    fields(strcmp(fields,'vbscf_values'))=[];
    fields_vec=[fields_vec {'vbscf_values'}];
end

if isempty(fields)||feof(fid)
    return;
end

data_fields=fieldnames(data);
num_lines=numel(data_in.(data_fields{1}));
% read in and parse the data
for i = 1: num_lines
    line = fgetl(fid);
    line=strrep(line,',,',', ,');
    tmp=strsplit(line,',');
    for ifi=1:numel(data_fields)
        idx_f=strcmpi(fields,data_fields{ifi});
        idx_f_v=find(strcmpi(fields_vec,data_fields{ifi}));
        
        if any(idx_f)
            if iscell(data.(fields{idx_f}))
                data.(fields{idx_f}){i}=deblank(tmp{idx_f});
            else
                data.(fields{idx_f})(i)=str2double(tmp{idx_f});
            end
        elseif ~isempty(idx_f_v)
            data.(fields_vec{idx_f_v}){i}=str2double(tmp((numel(fields)+idx_f_v-1):numel(fields_vec):end));
        else
            if iscell(data.(data_fields{ifi}))
                data.(data_fields{ifi}){i}=[];
            else
                data.(data_fields{ifi})(i)=nan;
            end
        end
        
        
        
        
    end
end
end
