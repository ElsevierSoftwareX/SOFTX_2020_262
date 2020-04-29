function remove_ST_cback(~,~,main_figure)

layer=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');
[trans_obj,idx_freq]=layer.get_trans(curr_disp);

trans_obj.rm_ST();
trans_obj.Data.remove_sub_data('singletarget');
curr_disp.ChannelID=layer.ChannelID{idx_freq};


end