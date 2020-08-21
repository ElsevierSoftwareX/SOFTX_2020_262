%% apply_st_detect_cback.m
%
% Apply single target detection on selected area or region_cl
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
% * 2017-03-22: header and comments updated according to new format (Alex Schimel)
% * 2017-03-02: first version (Yoann Ladroit)
%
% *EXAMPLE*
%
% TODO
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function apply_st_detect_cback(~,~,select_plot,main_figure)

update_algos('algo_name',{'SingleTarget'});
layer=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');

[trans_obj,~]=layer.get_trans(curr_disp);

switch class(select_plot)
    case 'region_cl'
        reg_obj=trans_obj.get_region_from_Unique_ID(union(curr_disp.Active_reg_ID,select_plot.Unique_ID));
    otherwise
        idx_ping=round(nanmin(select_plot.XData)):round(nanmax(select_plot.XData));
        idx_r=round(nanmin(select_plot.YData)):round(nanmax(select_plot.YData));
        reg_obj=region_cl('Name','Select Area','Idx_r',idx_r,'Idx_ping',idx_ping,'Unique_ID','select_area');
end
alg_name='SingleTarget';

show_status_bar(main_figure);
load_bar_comp=getappdata(main_figure,'Loading_bar');
new_region=reg_obj.merge_regions('overlap_only',0);
trans_obj.apply_algo(alg_name,'load_bar_comp',load_bar_comp,'reg_obj',new_region);

hide_status_bar(main_figure);
curr_disp.setField('singletarget');
display_tracks(main_figure);
update_st_tracks_tab(main_figure,'histo',1,'st',1);



end