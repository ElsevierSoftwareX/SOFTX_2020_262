%% import_bot_regs_from_xml_callback.m
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
% * |bot|: TODO: write description and info on variable
% * |reg|: TODO: write description and info on variable
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
function import_bot_regs_from_xml_callback(~,~,main_figure,bot_ver,reg_ver)

% info bot_ver and reg_ver:
% -1: load current xml file
%  0: load latest db version
%  n: load closest version to version n from db
%
% They should be -1 here, meaning we request XML version

layer = get_current_layer();

if isempty(layer)
    return;
end

if ~isempty(bot_ver) && ~isempty(reg_ver)
    war_str = ('WARNING: This will replace the currently defined Bottom and Regions with the latest saved version (xml). Proceed?');
elseif ~isempty(bot_ver) && isempty(reg_ver)
    war_str = ('WARNING: This will replace the currently defined Bottom with the latest saved version (xml). Proceed?');
elseif isempty(bot_ver) && ~isempty(reg_ver)
    war_str = ('WARNING: This will replace the currently defined Regions with the latest saved version (xml). Proceed?');
else
    return;
end

choice = question_dialog_fig(main_figure,'',war_str);
% Handle response
switch choice
    case 'No'
        return;
end

% load bot and/or reg
[~,~,~] = layer.load_bot_regs('bot_ver',bot_ver,'reg_ver',reg_ver);

clear_regions(main_figure,{},{});
display_bottom(main_figure);

display_regions('all');
curr_disp=get_esp3_prop('curr_disp');
curr_disp.setActive_reg_ID({});

set_alpha_map(main_figure,'main_or_mini',union({'main','mini'},layer.ChannelID));


end