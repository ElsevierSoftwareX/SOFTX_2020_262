%% detect_bottom_supervised.m
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
% * |src|: TODO: write description and info on variable
% * |cbackdata|: TODO: write description and info on variable
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
% * 2017-06-28: first version (Yoann Ladroit)
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function display_rectangle_bot_brush(src,~,main_figure)
if~(strcmpi(src.SelectionType,'Normal'))
    return;
end

layer=get_current_layer();
axes_panel_comp=getappdata(main_figure,'Axes_panel');
curr_disp=get_esp3_prop('curr_disp');

[trans_obj,idx_freq]=layer.get_trans(curr_disp);
context_menu=axes_panel_comp.echo_obj.echo_bt_surf.UIContextMenu;
childs=findobj(context_menu,'Type','uimenu');

for i=1:length(childs)
    if strcmp(childs(i).Checked,'on')
        dr=childs(i).UserData;
        break;
    end
    
end
Range= trans_obj.get_transceiver_range();
id=nanmean(diff(Range));
t=trans_obj.get_transceiver_time();
dt=(t(2)-t(1))*(24*60*60);
ratio=ceil(dt/id);

ah=axes_panel_comp.echo_obj.main_ax;

clear_lines(ah);


x_lim=get(ah,'xlim');
y_lim=get(ah,'ylim');


cp = ah.CurrentPoint;
ping_init =round(cp(1,1));
sample_init=round(cp(1,2));

if ping_init<x_lim(1)||ping_init>x_lim(end)||sample_init<y_lim(1)||sample_init>y_lim(end)
    return;
end

rect=findobj(ah,'Tag','brush_box');
if isempty(rect)
    rectangle(ah,'Position',[ping_init-dr sample_init-ratio*dr 2*dr dr*2*ratio],'Tag','brush_box');
else
    rect.Position=[ping_init-dr sample_init-ratio*dr 2*dr dr*2*ratio];
end



end
