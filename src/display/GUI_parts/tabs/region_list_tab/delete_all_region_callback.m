%% delete_all_region_callback.m
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
% * 2017-03-28: header (Alex Schimel)
% * YYYY-MM-DD: first version (Yoann Ladroit)
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function delete_all_region_callback(~,~,main_figure)

war_str='Are you sure you want to delete all current regions?';
choice=question_dialog_fig(main_figure,'',war_str,'timeout',10);

% Handle response
switch choice
    case 'Yes'
        
        layer=get_current_layer();
        curr_disp=get_esp3_prop('curr_disp');
        [trans_obj,~]=layer.get_trans(curr_disp);
        list_reg = trans_obj.regions_to_str();
        axes_panel_comp=getappdata(main_figure,'Axes_panel');
        ah=axes_panel_comp.echo_obj.main_ax;
        clear_lines(ah);
        
        if ~isempty(list_reg)
            old_regs=trans_obj.Regions;
            trans_obj.rm_regions();
            curr_disp.Reg_changed_flag=1;
            
            display_regions('both');            
            
            add_undo_region_action(main_figure,trans_obj,old_regs,trans_obj.Regions);
  
            curr_disp.setActive_reg_ID({});
            
            curr_disp.Reg_changed_flag=1;
            
        else
            return;
        end
end



end