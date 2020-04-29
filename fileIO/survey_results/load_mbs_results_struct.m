function [header,data] = load_mbs_results_struct(filename)

[fid, message] = fopen(filename);

if fid == -1
    disp(message)
    return
end

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
        header.Title = r(3:length(r));
    end
    if strcmp(t,'voyage')
        header.Voyage = r(3:length(r));
    end
    if strcmp(t,'author')
        header.Author = r(3:length(r));
    end
    if strcmp(t,'main_species')
        header.Main_species = r(3:length(r));
    end
    if strcmp(t,'areas')
        header.Areas = r(3:length(r));
    end
    if strcmp(t,'created')
        header.Created = r(3:length(r));
    end
    if strcmp(t,'comments')
        header.Comments = r(3:length(r));
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

data=init_data_struct(header.num_strata, header.num_transects,header.num_regions);

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
        data_in=data.(field);
        tmp=read_mbs_data_block(fid,data_in);
        if ~isempty(tmp)
            data.(field) = tmp;
        end
    end
    line = fgetl(fid);
end

fclose(fid);

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

function obj=init_data_struct(nb_strat,nb_trans,nb_reg)


p = inputParser;
addRequired(p,'nb_strat',@(x) x>0);
addRequired(p,'nb_trans',@(x) x>0);
addRequired(p,'nb_reg',@(x) x>=0);
parse(p,nb_strat,nb_trans,nb_reg);


mat_de=nan(1,nb_strat);
cell_de={cell(1,nb_strat)};


obj.stratumSum =struct('snapshot',mat_de,'stratum',cell_de,'no_transects',mat_de,...
    'abscf_mean',mat_de,'abscf_sd',mat_de,'abscf_wmean',mat_de,'abscf_var',mat_de,...
    'abscf_with_shz_mean',mat_de,'abscf_with_shz_sd',mat_de,...
    'abscf_with_shz_wmean',mat_de,'abscf_with_shz_var',mat_de,...
    'time_start',mat_de,'time_end',mat_de);

mat_de=nan(1,nb_trans);
cell_de={cell(1,nb_trans)};
obj.transectSum = struct('snapshot',mat_de,'type',cell_de,'stratum',cell_de,'transect',mat_de,...
    'dist',mat_de,'vbscf',mat_de,'abscf',mat_de,'mean_d',mat_de,'pings',mat_de,...
    'av_speed',mat_de,'start_lat',mat_de,'start_lon',mat_de,'finish_lat',mat_de,...
    'finish_lon',mat_de,'shadow_zone_abscf',mat_de,'time_start',mat_de,...
    'time_end',mat_de,'nb_pings_tot',mat_de,'nb_st',mat_de,'nb_tracks',mat_de);

obj.slicedTransectSum = struct('snapshot',mat_de,'type',cell_de,'stratum',cell_de,'transect',mat_de,...
    'slice_size',mat_de,'num_slices',mat_de,'latitude',cell_de,'longitude',cell_de,...
    'slice_abscf',cell_de,'time_start',cell_de,'time_end',cell_de,...
    'slice_nb_tracks',cell_de,'slice_nb_st',cell_de,'slice_shadow_zone_abscf',cell_de,...
    'slice_hill_weight',cell_de,'latitude_e',cell_de,'longitude_e',cell_de);

mat_de=nan(1,nb_reg);
cell_de={cell(1,nb_reg)};

obj.regionSum = struct('snapshot',mat_de,'type',cell_de,'stratum',cell_de,'transect',mat_de,...
    'file',cell_de,'region_id',mat_de,'ref',cell_de,'slice_size',mat_de,'good_pings',mat_de,...
    'start_d',mat_de,'mean_d',mat_de,'finish_d',mat_de,'av_speed',mat_de,'vbscf',mat_de,...
    'abscf',mat_de,'time_start',mat_de,'time_end',mat_de,'tag',cell_de);
obj.regionSumAbscf = struct('snapshot',mat_de,'type',cell_de,'stratum',cell_de,'transect',mat_de,...
    'file',cell_de,'region_id',mat_de,'num_v_slices',mat_de,'transmit_start',cell_de,...
    'latitude',cell_de,'longitude',cell_de,'column_abscf',cell_de,'time_start',cell_de,'time_end',cell_de);
obj.regionSumVbscf = struct('snapshot',mat_de,'type',cell_de,'stratum',cell_de,'transect',mat_de,...
    'file',cell_de,'region_id',mat_de,'num_h_slices',mat_de,'num_v_slices',mat_de,...
    'region_vbscf',mat_de,'vbscf_values',cell_de,'time_start',cell_de,'time_end',cell_de);
obj.regionsIntegrated= struct('snapshot',mat_de,'type',cell_de,'stratum',cell_de,'transect',mat_de,...
    'file',cell_de,'Region',cell_de,'RegOutput',cell_de);

end