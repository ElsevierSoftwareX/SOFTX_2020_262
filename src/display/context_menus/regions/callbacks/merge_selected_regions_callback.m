%% merge_selected_regions_callback.m
%
% TODO: write short description of function
%
%% Help
%
% *USE*
%
% TODO: write longer description of function
%
% *INPUT VARIABLES*
%
% * |main_figure|: TODO: write description and info on variable
%
% *OUTPUT VARIABLES*
%
% NA
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2018-11-27: first version (Yoann Ladroit)
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function merge_selected_regions_callback(~,~,main_figure)

layer=get_current_layer();

if isempty(layer)
    return;
end

curr_disp=get_esp3_prop('curr_disp');

[trans_obj,~]=layer.get_trans(curr_disp);
selected_regs_ids=curr_disp.Active_reg_ID;

if ~isempty(trans_obj.Regions)&&~isempty(selected_regs_ids)
     idx_regs=trans_obj.find_regions_Unique_ID(selected_regs_ids);

    old_regs=trans_obj.Regions;

    new_regions=trans_obj.Regions(idx_regs).merge_regions('overlap_only',0);

    layer.delete_regions_from_uid(curr_disp,selected_regs_ids);
    IDs=trans_obj.add_region(new_regions);
   
    display_regions(main_figure,'both');
   
    add_undo_region_action(main_figure,trans_obj,old_regs,trans_obj.Regions);

    if ~isempty(IDs)
    curr_disp.setActive_reg_ID({});
    curr_disp.Reg_changed_flag=1;
    end
    

end

end
