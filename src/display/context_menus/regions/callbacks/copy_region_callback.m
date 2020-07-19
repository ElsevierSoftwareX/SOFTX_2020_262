function copy_region_callback(~,~,main_figure,idx_freq_end)
layer=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');
[trans_obj,idx_freq]=layer.get_trans(curr_disp);
if ~isempty(idx_freq_end)
    idx_other=setdiff(1:numel(layer.Frequencies),idx_freq);
    if isempty(idx_other)
        return;
    end
    
    list_freq_str = cellfun(@(x,y) sprintf('%.0f kHz: %s',x,y),num2cell(layer.Frequencies(idx_other)/1e3), deblank(layer.ChannelID(idx_other)),'un',0);
    
    if isempty(list_freq_str)
        return;
    end
    
    [idx_freq_end,val] = listdlg_perso(main_figure,'',list_freq_str);
    if val==0 || isempty(idx_freq_end)
        return;
    end
    idx_freq_end=layer.find_cid_idx(layer.ChannelID(idx_other(idx_freq_end)));
end

for i=1:length(curr_disp.Active_reg_ID)
    ID=curr_disp.Active_reg_ID{i};    
    reg_curr=trans_obj.get_region_from_Unique_ID(ID);
    
    layer.copy_region_across(idx_freq,reg_curr,idx_freq_end);
end

display_regions('all');
end