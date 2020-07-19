function find_spikes_cback(~,~,select_plot,main_figure)

update_algos('algo_name',{'SpikesRemoval'});
layer=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');
[trans_obj,idx_freq]=layer.get_trans(curr_disp);

switch class(select_plot)
    case 'region_cl'
        reg_obj=trans_obj.get_region_from_Unique_ID(curr_disp.Active_reg_ID);
    otherwise
        idx_pings=round(nanmin(select_plot.XData)):round(nanmax(select_plot.XData));
        idx_r=round(nanmin(select_plot.YData)):round(nanmax(select_plot.YData));
        reg_obj=region_cl('Name','Select Area','Idx_r',idx_r,'Idx_pings',idx_pings,'Unique_ID','select_area');
end

show_status_bar(main_figure);
load_bar_comp=getappdata(main_figure,'Loading_bar');
new_region=reg_obj.merge_regions('overlap_only',0);
trans_obj.apply_algo('SpikesRemoval','load_bar_comp',load_bar_comp,'reg_obj',new_region);

hide_status_bar(main_figure);

set_alpha_map(main_figure,'update_under_bot',0,'update_cmap',0);


end