
function set_alpha_map(main_figure,varargin)

if ~isdeployed
    disp('set_alpha_map')
end
layer=get_current_layer();
if isempty(layer)
    return;
end
curr_disp=get_esp3_prop('curr_disp');
p = inputParser;

addRequired(p,'main_figure',@ishandle);
addParameter(p,'main_or_mini',union({'main','mini'},curr_disp.ChannelID,'stable'));
addParameter(p,'update_bt',1);
addParameter(p,'update_under_bot',1);
addParameter(p,'update_cmap',1);

parse(p,main_figure,varargin{:});

%alpha_map_fig=get(main_figure,'alphamap')%6 elts vector: first: empty, second: under clim(1), third: underbottom, fourth: bad trans, fifth regions, sixth normal]

update_bt=p.Results.update_bt;
update_under_bot=p.Results.update_under_bot;
update_cmap=p.Results.update_cmap;

if~iscell(p.Results.main_or_mini)
    main_or_mini={p.Results.main_or_mini};
else
    main_or_mini=p.Results.main_or_mini;
end

[echo_obj,trans_obj,~,~]=get_axis_from_cids(main_figure,main_or_mini);

if isempty(echo_obj)
    return;
end


for iax=1:length(echo_obj)
    
    echo_obj(iax).set_echo_alphamap(trans_obj{iax},...
        'curr_disp',curr_disp,...
        'update_under_bot',update_under_bot,...
        'update_bt',update_bt,...
        'update_cmap',update_cmap)
    
end

end