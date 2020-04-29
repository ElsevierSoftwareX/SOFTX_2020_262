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
    [~,main_axes_tot,~,~,~,~]=get_axis_from_cids(main_figure,union({'main' 'mini'}, layer.ChannelID));
else
    [~,main_axes_tot,~,~,~,~]=get_axis_from_cids(main_figure,channelIDS);
end


for iax=1:length(main_axes_tot)
    if isempty(ids)
        delete(findobj(ancestor(main_axes_tot(iax),'figure'),'Type','UiContextMenu','-and','Tag','RegionContextMenu'));
        delete(findobj(main_axes_tot(iax),'tag','region','-or','tag','region_text','-or','tag','region_cont'));
    else
        for i=1:numel(ids)
            delete(findobj(main_axes_tot(iax),{'tag','region','-or','tag','region_text','-or','tag','region_cont'},'-and','UserData',ids{i}));
            delete(findobj(ancestor(main_axes_tot(iax),'figure'),'Type','UiContextMenu','-and','Tag','RegionContextMenu','-and','UserData',ids{i}));
        end
    end

end

if ~isdeployed
    disp_perso(main_figure,'')
end

end