%% toggle_func.m
%
% TODO
%
%% Help
%
% *USE*
%
% TODO
%
% *INPUT VARIABLES*
%
% * |src|: TODO
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
% * 2017-03-28: header (Alex Schimel)
% * YYYY-MM-DD: first version (Yoann Ladroit)
%
% *EXAMPLE*
%
% TODO
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function toggle_func(src, ~,main_figure)
%profile on;
%cursor_mode_tool_comp=getappdata(main_figure,'Cursor_mode_tool');
axes_panel_comp=getappdata(main_figure,'Axes_panel');
curr_disp=get_esp3_prop('curr_disp');


switch class(src)
    case {'matlab.ui.container.toolbar.ToggleTool','matlab.ui.container.toolbar.PushTool','matlab.ui.container.toolbar.ToggleSplitTool'}
        tag=src.Tag;
        src_out=src;
    case 'char'
        src_out.State='on';
        tag=src;
end

cursor_tools_comp=getappdata(main_figure,'Cursor_mode_tool');

 childs=[findobj(cursor_tools_comp.cursor_mode_tool,'type','uitoggletool');...
     findobj(cursor_tools_comp.cursor_mode_tool,'type','uitogglesplittool')];
 for i=1:length(childs)
     if ~strcmp(get(childs(i),'tag'),tag)
         set(childs(i),'state','off');
     end
 end

if isa(src_out,'matlab.ui.container.toolbar.PushTool')
    %profile off;
    return;
end


if isa(src_out,'matlab.ui.container.toolbar.ToggleSplitTool')||isa(src_out,'matlab.ui.container.toolbar.ToggleTool')
    state=src_out.State;
else
    state='on';
end
%iptPointerManager(main_figure,'enable');
replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',2);
replace_interaction(main_figure,'interaction','WindowButtonUpFcn','id',2);
 
switch state
    case'on'
        %iptPointerManager(main_figure,'disable');
        delete(axes_panel_comp.bad_transmits.UIContextMenu);
        delete(axes_panel_comp.bottom_plot.UIContextMenu);
        axes_panel_comp.bad_transmits.UIContextMenu=[];
        axes_panel_comp.bottom_plot.UIContextMenu=[];
        
        switch tag
            case 'pan'
                replace_interaction(main_figure,'interaction','WindowButtonDownFcn','id',1,'interaction_fcn',{@pan_cback,main_figure});
            case 'zin'
                replace_interaction(main_figure,'interaction','WindowButtonDownFcn','id',1,'interaction_fcn',{@zoom_in_callback,main_figure});
            case 'zout'
                replace_interaction(main_figure,'interaction','WindowButtonDownFcn','id',1,'interaction_fcn',{@zoom_out_callback,main_figure});
            case 'bt'
                replace_interaction(main_figure,'interaction','WindowButtonDownFcn','id',1,'interaction_fcn',{@mark_bad_transmit,main_figure});
            case 'ed_bot'
                replace_interaction(main_figure,'interaction','WindowButtonDownFcn','id',1,'interaction_fcn',{@edit_bottom,main_figure});
            case 'ed_bot_sup'
                context_menu=uicontextmenu(ancestor(axes_panel_comp.bad_transmits,'figure'),'Tag','btCtxtMenu');
                axes_panel_comp.bad_transmits.UIContextMenu=context_menu;
                uimenu(context_menu,'Label','Small','userdata',5,'Callback',@check_only_one);
                uimenu(context_menu,'Label','Medium','userdata',10,'Callback',@check_only_one,'checked','on');
                uimenu(context_menu,'Label','Large','userdata',25,'Callback',@check_only_one);
                uimenu(context_menu,'Label','Extra','userdata',50,'Callback',@check_only_one);
                
                replace_interaction(main_figure,'interaction','WindowButtonDownFcn','id',1,'interaction_fcn',{@detect_bottom_supervised,main_figure});
                %replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',3,'interaction_fcn',{@display_rectangle_bot_brush,main_figure});
            case 'ed_bot_spline'
                
                context_menu=uicontextmenu(ancestor(axes_panel_comp.bad_transmits,'figure'),'Tag','btCtxtMenu');
                axes_panel_comp.bad_transmits.UIContextMenu=context_menu;
                uimenu(context_menu,'Label','Small radius (2px)','userdata',2,'Callback',@check_only_one);
                uimenu(context_menu,'Label','Medium radius (5px)','userdata',5,'Callback',@check_only_one,'checked','on');
                uimenu(context_menu,'Label','Large radius (10px)','userdata',10,'Callback',@check_only_one);
                uimenu(context_menu,'Label','Extra Large radius (50px)','userdata',50,'Callback',@check_only_one);
                uimenu(context_menu,'Label','Stupidly Large radius (100px)','userdata',100,'Callback',@check_only_one);
                
                replace_interaction(main_figure,'interaction','WindowButtonDownFcn','id',1,'interaction_fcn',{@push_bottom,main_figure});
            case 'loc'
                replace_interaction(main_figure,'interaction','WindowButtonDownFcn','id',1,'interaction_fcn',{@disp_loc,main_figure});
            case 'meas'
                replace_interaction(main_figure,'interaction','WindowButtonDownFcn','id',1,'interaction_fcn',{@measure_distance,main_figure});
            case 'create_reg_rect'
                replace_interaction(main_figure,'interaction','WindowButtonDownFcn','id',1,'interaction_fcn',{@create_region,main_figure,'','rectangular'});
            case 'create_reg_horz'
                replace_interaction(main_figure,'interaction','WindowButtonDownFcn','id',1,'interaction_fcn',{@create_region,main_figure,'','horizontal'});
            case 'create_reg_vert'
                replace_interaction(main_figure,'interaction','WindowButtonDownFcn','id',1,'interaction_fcn',{@create_region,main_figure,'','vertical'});
            case 'create_reg_poly'
                replace_interaction(main_figure,'interaction','WindowButtonDownFcn','id',1,'interaction_fcn',{@create_region,main_figure,'Polygon',''});
            case 'create_reg_hd'
                replace_interaction(main_figure,'interaction','WindowButtonDownFcn','id',1,'interaction_fcn',{@create_region,main_figure,'Hand Drawn',''});
            case 'draw_line'
                replace_interaction(main_figure,'interaction','WindowButtonDownFcn','id',1,'interaction_fcn',{@draw_line,main_figure});
            case 'add_st'
                replace_interaction(main_figure,'interaction','WindowButtonDownFcn','id',1,'interaction_fcn',{@add_st,main_figure});
            case 'erase_soundings'
                replace_interaction(main_figure,'interaction','WindowButtonDownFcn','id',1,'interaction_fcn',{@brush_soundings,main_figure});
            otherwise
                replace_interaction(main_figure,'interaction','WindowButtonDownFcn','id',1,'interaction_fcn',{@select_area_cback,main_figure});
                cursor_tools_comp.pointer.State='on';
%                 iptPointerManager(main_figure,'enable');
                create_context_menu_main_echo(main_figure);
                create_context_menu_bottom(main_figure,axes_panel_comp.bottom_plot);
        end
    case 'off'
        replace_interaction(main_figure,'interaction','WindowButtonDownFcn','id',1,'interaction_fcn',{@select_area_cback,main_figure});
        cursor_tools_comp.pointer.State='on';
        %iptPointerManager(main_figure,'enable');    
        create_context_menu_main_echo(main_figure);
        create_context_menu_bottom(main_figure,axes_panel_comp.bottom_plot);
        
end
order_stacks_fig(main_figure,curr_disp);
%profile off;
%profile viewer;
end

function check_only_one(src,~)
uimenu_parent=get(src,'Parent');
childs=findobj(uimenu_parent,'Type','uimenu');  

for i=1:length(childs)
    if src~=childs(i)
        set(childs(i), 'Checked', 'off');
    end
end

set(src, 'Checked', 'on');


end
