%% remove_cvs_callback.m
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
% * |main_figure|: TODO: write description and info on variable
%
% *OUTPUT VARIABLES*
%
% NA
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2017-03-28: header (Alex Schimel)
% * YYYY-MM-DD: first version (Yoann Ladroit)
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function remove_cvs_callback(~,~,main_figure)

layers=get_esp3_prop('layers');

choice=question_dialog_fig(main_figure,'','WARNING: This will remove all CVS Regions?');

switch choice
    case 'No'
        return;
end

for i=1:length(layers)
    for uui=1:length(layers(i).Frequencies)
        layers(i).Transceivers(uui).rm_region_origin('esp2');
    end
end
set_esp3_prop('layers',layers);

display_bottom(main_figure);

display_regions('all');
curr_disp=get_esp3_prop('curr_disp');
[trans_obj,~]=layer.get_trans(curr_disp);
curr_disp.setActive_reg_ID(trans_obj.get_reg_first_Unique_ID());

set_alpha_map(main_figure,'main_or_mini',union({'main','mini'},layer.ChannelID));


end