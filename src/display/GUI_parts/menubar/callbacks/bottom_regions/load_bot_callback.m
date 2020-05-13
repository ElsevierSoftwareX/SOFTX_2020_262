function load_bot_callback(~,~,main_figure)

layer=get_current_layer();

if isempty(layer)
return;
end
    
app_path=get_esp3_prop('app_path');

layer.CVS_BottomRegions(app_path.cvs_root.Path_to_folder,'BotCVS',1,'RegCVS',0);

display_bottom(main_figure);
set_alpha_map(main_figure,'main_or_mini',union({'main','mini'},layer.ChannelID));
order_stacks_fig(main_figure,[]);
end
