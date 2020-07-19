    %% apply_school_detect_cback.m
%
% Apply school detection on selected area or region_cl
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
% * 2017-03-07: first version (Yoann Ladroit)
%
% *EXAMPLE*
%
% TODO
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function apply_school_detect_cback(~,~,select_plot,main_figure)

update_algos('algo_name',{'SchoolDetection'});
layer=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');
[trans_obj,~]=layer.get_trans(curr_disp);
switch class(select_plot)
    case 'region_cl'
        reg_obj=trans_obj.get_region_from_Unique_ID(curr_disp.Active_reg_ID);
    otherwise
        idx_pings=round(nanmin(select_plot.XData)):round(nanmax(select_plot.XData));
        idx_r=round(nanmin(select_plot.YData)):round(nanmax(select_plot.YData));
        reg_obj=region_cl('Name','Select Area','Idx_r',idx_r,'Idx_pings',idx_pings,'Unique_ID','select_area');
end

if isempty(reg_obj)
    return;
end

alg_name='SchoolDetection';

show_status_bar(main_figure);
load_bar_comp=getappdata(main_figure,'Loading_bar');
old_regs=trans_obj.Regions;
new_region=reg_obj.merge_regions('overlap_only',0);
trans_obj.apply_algo(alg_name,'load_bar_comp',load_bar_comp,'reg_obj',new_region);

add_undo_region_action(main_figure,trans_obj,old_regs,trans_obj.Regions);

hide_status_bar(main_figure);
    
display_regions('both');
curr_disp.setActive_reg_ID({});


end