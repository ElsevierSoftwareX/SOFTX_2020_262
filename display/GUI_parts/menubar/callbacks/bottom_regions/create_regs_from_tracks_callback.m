function create_regs_from_tracks_callback(~,~,type,main_figure,uid)
layer=get_current_layer();

if isempty(layer)
return;
end
    
curr_disp=get_esp3_prop('curr_disp');

[trans_obj,idx_freq]=layer.get_trans(curr_disp);
if isempty(trans_obj)
    return;
end

trans_obj.create_track_regs('Type',type,'uid',uid);

display_tracks(main_figure);
update_reglist_tab(main_figure,0);
display_regions(main_figure,'both');
order_stacks_fig(main_figure,curr_disp);



