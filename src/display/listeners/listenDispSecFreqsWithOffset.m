function listenDispSecFreqsWithOffset(src,evt,main_figure)
layer=get_current_layer();
load_secondary_freq_win(main_figure,0);
init_sec_link_props(main_figure);
update_axis(main_figure,1,'main_or_mini',layer.ChannelID);
set_alpha_map(main_figure,'main_or_mini',layer.ChannelID);
update_cmap(main_figure);
update_grid(main_figure);
display_bottom(main_figure,layer.ChannelID);
display_regions(layer.ChannelID);
init_link_prop(main_figure);
end