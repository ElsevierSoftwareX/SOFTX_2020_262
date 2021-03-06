%% shift_bottom_callback.m
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
% * |select_plot|: TODO: write description and info on variable
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
% * 2017-03-28: first version (Yoann Ladroit)
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function shift_bottom_callback(~,~,select_plot,main_figure)

layer=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');

[trans_obj,~]=layer.get_trans(curr_disp);

if ~isempty(select_plot)
    switch class(select_plot)
        case 'region_cl'
            reg_obj=trans_obj.get_region_from_Unique_ID(curr_disp.Active_reg_ID);
        otherwise
            idx_pings=round(nanmin(select_plot.XData)):round(nanmax(select_plot.XData));
            idx_r=round(nanmin(select_plot.YData)):round(nanmax(select_plot.YData));
            reg_obj=region_cl('Name','Select Area','Idx_r',idx_r,'Idx_pings',idx_pings,'Unique_ID','select_area');
    end
else
    idx_r = 1:length(trans_obj.get_transceiver_range());
    idx_pings = 1:length(trans_obj.get_transceiver_pings());
    reg_obj=region_cl('Name','Select Area','Idx_r',idx_r,'Idx_pings',idx_pings,'Unique_ID','select_area');
end

[answer,cancel]=input_dlg_perso(main_figure,'Enter value',{'Shift Bottom (+ up / - down)'},...
    {'%d'},{0});
if cancel
    return;
end

old_bot=trans_obj.Bottom;
for i=1:numel(reg_obj)
    idx_pings=reg_obj(i).Idx_pings;
    
    trans_obj.shift_bottom(answer{1},idx_pings);
end

curr_disp.Bot_changed_flag=1;



bot=trans_obj.Bottom;
curr_disp.Bot_changed_flag=1;

add_undo_bottom_action(main_figure,trans_obj,old_bot,bot);

set_alpha_map(main_figure,'update_bt',0);
display_bottom(main_figure);


end