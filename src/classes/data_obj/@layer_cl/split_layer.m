%% split_layer.m
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
function new_layers=split_layer(layer_obj)

%survey_data=layer_obj.SurveyData;
[start_time,end_time]=layer_obj.get_time_bound_files();

new_layers(length(layer_obj.Filename))=layer_cl();

for ifi=1:length(layer_obj.Filename)
    new_layers(ifi).regenerate_ID_num();
    new_layers(ifi).Filename=layer_obj.Filename(ifi);
    new_layers(ifi).Filetype=layer_obj.Filetype;
    new_layers(ifi).Frequencies=layer_obj.Frequencies;
    new_layers(ifi).ChannelID=layer_obj.ChannelID;
    new_layers(ifi).AvailableChannelIDs=layer_obj.AvailableChannelIDs;
    new_layers(ifi).AvailableFrequencies=layer_obj.AvailableFrequencies;
    new_layers(ifi).EnvData=copy_env_data(layer_obj.EnvData);
    idx_t=find(new_layers(ifi).AttitudeNav.Time>=start_time(ifi)&new_layers(ifi).AttitudeNav.Time<=end_time(ifi));
    if ~isempty(idx_t)
        new_layers(ifi).AttitudeNav=layer_obj.AttitudeNav.get_AttitudeNav_idx_section(idx_t);
        new_layers(ifi).GPSData=layer_obj.GPSData.get_GPSDData_idx_section(idx_t);
    end
    
    for itrans=1:length(layer_obj.Frequencies)
        new_layers(ifi).Transceivers(itrans)=layer_obj.Transceivers(itrans).get_transceiver_from_file_ID(ifi);
    end
    
    for il=1:length(layer_obj.Lines)
        line_temp=layer_obj.Lines(il).get_line_time_section(start_time(ifi),end_time(ifi));
        line_temp.ID=layer_obj.Lines(il).ID;
       new_layers(ifi).add_lines(line_temp);
    end
    
    new_layers(ifi).GPSData=layer_obj.GPSData.get_GPSDData_time_section(start_time(ifi),end_time(ifi));
%     new_layers(ifi)
%     new_layers(ifi).set_survey_data(survey_data);  
end


end



