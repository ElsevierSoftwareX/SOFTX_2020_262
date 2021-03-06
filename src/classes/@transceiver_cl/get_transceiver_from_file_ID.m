%% get_transceiver_from_file_ID.m
%
% TODO: write short description of function
%
%% Help
%
% *USE*
%
% TODO: write longer description of function
%
% *INPUT VARIABLES*
%
% * |layer_obj|: TODO: write description and info on variable
%
% *OUTPUT VARIABLES*
%
% * |new_layers|: TODO: write description and info on variable
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2017-05-30: first version (Yoann Ladroit). TODO: complete date and comment
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function

function trans_file_ID=get_transceiver_from_file_ID(trans_obj,fileID)
fileID_vec=trans_obj.get_fileID();

idx_file=find(fileID_vec==fileID);

if isempty(idx_file)
    trans_file_ID=[];
    return;
end

trans_file_ID=transceiver_cl();
trans_file_ID.Data=trans_obj.Data.get_data_idx_file(fileID);

trans_file_ID.Range=trans_obj.Range(1:nanmax(trans_file_ID.Data.Nb_samples));
trans_file_ID.Spikes=trans_obj.Spikes(1:nanmax(trans_file_ID.Data.Nb_samples),idx_file);

trans_file_ID.Time=trans_obj.Time(idx_file);
trans_file_ID.Bottom=trans_obj.Bottom.get_bottom_idx_section(idx_file);

for ireg=1:numel(trans_obj.Regions)
    [reg_temp,fids]=trans_obj.Regions(ireg).split_region(fileID_vec,1);
    if any(fids==fileID)
        trans_file_ID.add_region(reg_temp(fids==fileID),'Ping_offset',idx_file(1)-1);
    end
end

trans_file_ID.Params=trans_obj.Params.get_params_idx_section(idx_file);

trans_file_ID.Config=trans_obj.Config;
trans_file_ID.Filters=trans_obj.Filters;
trans_file_ID.Algo=trans_obj.Algo;
trans_file_ID.Mode=trans_obj.Mode;
trans_file_ID.TransducerDepth=trans_obj.TransducerDepth(idx_file);
%trans_file_ID.TransducerImpedance = cell(1,numel(idx_file));
if ~isempty(trans_obj.TransducerImpedance)
    trans_file_ID.TransducerImpedance=trans_obj.TransducerImpedance(idx_file);
end

trans_file_ID.GPSDataPing=trans_obj.GPSDataPing.get_GPSDData_idx_section(idx_file);
trans_file_ID.AttitudeNavPing=trans_obj.AttitudeNavPing.get_AttitudeNav_idx_section(idx_file);
trans_file_ID.Alpha=trans_obj.Alpha;
trans_file_ID.Alpha_ori=trans_obj.Alpha_ori;


end

