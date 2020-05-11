%% apply_track_target_cback.m
%
% Apply target tracking on selected area or region_cl
%
%% Help
%
% *USE*
%
% TODO
%
% *INPUT VARIABLES*
%
% * |select_plot|: TODO
% * |main_figure|: Handle to main ESP3 window
%
% *OUTPUT VARIABLES*
%
% NA
%
% *RESEARCH NOTES*
%
% TODO
%
% *NEW FEATURES*
%
% * 2017-09-04: first version (Yoann Ladroit)
%
% *EXAMPLE*
%
% TODO
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function apply_track_target_cback(~,~,select_plot,main_figure)

update_algos(main_figure,'algo_name',{'TrackTarget'});

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

alg_name='TrackTarget';

show_status_bar(main_figure);
load_bar_comp=getappdata(main_figure,'Loading_bar');
new_region=reg_obj.merge_regions('overlap_only',0);
trans_obj.apply_algo(alg_name,'load_bar_comp',load_bar_comp,'reg_obj',new_region);
    
hide_status_bar(main_figure);
display_tracks(main_figure);
update_st_tracks_tab(main_figure,'histo',1,'st',0);
update_multi_freq_disp_tab(main_figure,'ts_f',0);


end