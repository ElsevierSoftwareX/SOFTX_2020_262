function import_angles_cback(~,~,main_figure) 

layer=get_current_layer();

curr_disp=get_esp3_prop('curr_disp');
[trans_obj,idx_freq]=layer.get_trans(curr_disp);


list_freq_str = cellfun(@(x,y) sprintf('%.0f kHz: %s',x,y),num2cell(layer.Frequencies/1e3), layer.ChannelID,'un',0);
[select,val] = listdlg_perso(main_figure,'Choose Channels',list_freq_str,'init_val',idx_freq);
if ~isempty(select)
    select=select(1);
end
if val==0||isempty(select)||select==idx_freq
    return;
end


acrossangle_ori=trans_obj.Data.get_datamat('acrossangle');
acrossangle_new=layer.Transceivers(select).Data.get_datamat('acrossangle');
alongangle_new=layer.Transceivers(select).Data.get_datamat('alongangle');

trans_obj.Data.replace_sub_data_v2('acrossangle',imresize(acrossangle_new,size(acrossangle_ori),'nearest'),[],[]);
trans_obj.Data.replace_sub_data_v2('alongangle',imresize(alongangle_new,size(acrossangle_ori),'nearest'),[],[]);
update_display(main_figure,0,1);

end