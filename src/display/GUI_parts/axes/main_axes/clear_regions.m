%% clear_regions.m
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
% * |ids|: TODO: write description and info on variable
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
% * 2017-04-02: header (Alex Schimel).
% * 2017-03-29: first version (Yoann Ladroit).
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function clear_regions(main_figure,ids,channelIDS)

%profile on;
if ~isdeployed
    disp_perso(main_figure,'Clear regions')
end

if ~iscell(ids)
    ids={ids};
end
layer=get_current_layer();

if isempty(channelIDS)
    [echo_obj,~,~,~]=get_axis_from_cids(main_figure,union({'main' 'mini'}, layer.ChannelID));
else
    [echo_obj,~,~,~]=get_axis_from_cids(main_figure,channelIDS);
end

if isempty(echo_obj)
    return;
end

echo_obj.clear_echo_regions([]);

if ~isdeployed
    disp_perso(main_figure,'')
end

end