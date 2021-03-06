function load_cursor_tool(main_figure)

if ~isdeployed
    disp('Loading Toolbar');
end

cursor_mode_tool_comp.cursor_mode_tool=uitoolbar(main_figure,'Tag','toolbar_esp3');
app_path_main=whereisEcho();
icon=get_icons_cdata(fullfile(app_path_main,'icons'));

cursor_mode_tool_comp.pointer=uitoggletool(cursor_mode_tool_comp.cursor_mode_tool,'CData',icon.pointer,'TooltipString','Normal (0)','Tag','nor');
cursor_mode_tool_comp.zoom_in=uitoggletool(cursor_mode_tool_comp.cursor_mode_tool,'CData',icon.zin,'TooltipString','Zoom In (1)','Tag','zin');
cursor_mode_tool_comp.zoom_out=uitoggletool(cursor_mode_tool_comp.cursor_mode_tool,'CData',icon.zout,'TooltipString','Zoom Out (shift+1)','Tag','zout');
cursor_mode_tool_comp.bad_trans=uitoggletool(cursor_mode_tool_comp.cursor_mode_tool,'CData',icon.bad_trans ,'TooltipString','Bad Pings (2)','Tag','bt');
cursor_mode_tool_comp.edit_bottom=uitogglesplittool(cursor_mode_tool_comp.cursor_mode_tool,'CData',icon.edit_bot,'TooltipString','Edit Bottom (3)','Tag','ed_bot');
cursor_mode_tool_comp.create_reg=uitogglesplittool(cursor_mode_tool_comp.cursor_mode_tool,'CData',icon.create_reg_rect ,'TooltipString','Create Rectangular region (4)','Tag','create_reg_rect');
cursor_mode_tool_comp.measure=uitoggletool(cursor_mode_tool_comp.cursor_mode_tool,'CData',icon.ruler ,'TooltipString','Measure Distance (5)','Tag','meas');
cursor_mode_tool_comp.pan=uitoggletool(cursor_mode_tool_comp.cursor_mode_tool,'CData',icon.pan ,'TooltipString','Pan (6)','Tag','pan');

childs=[findobj(main_figure,'type','uitoggletool');findobj(main_figure,'type','uitogglesplittool')];
set(childs,...
    'ClickedCallback',{@set_curr_disp_mode,main_figure});

cursor_mode_tool_comp.undo = uipushtool('parent',cursor_mode_tool_comp.cursor_mode_tool,'CData',icon.undo,'TooltipString','Undo (ctrl+z)','Tag','undo''parent','ClickedCallback','uiundo(gcbf,''execUndo'')','Separator','on');
cursor_mode_tool_comp.redo = uipushtool('parent',cursor_mode_tool_comp.cursor_mode_tool,'CData',icon.redo,'TooltipString','Redo (ctrl+y)','Tag','redo','ClickedCallback','uiundo(gcbf,''execRedo'')');

cursor_mode_tool_comp.previous=uipushtool(cursor_mode_tool_comp.cursor_mode_tool,'CData',icon.prev_lay ,'TooltipString','Previous Layer (p)','ClickedCallback',{@change_layer_callback,main_figure,'prev'},'Separator','on');
cursor_mode_tool_comp.next=uipushtool(cursor_mode_tool_comp.cursor_mode_tool,'CData',icon.next_lay ,'TooltipString','Next Layer (n)','ClickedCallback',{@change_layer_callback,main_figure,'next'});
cursor_mode_tool_comp.del=uipushtool(cursor_mode_tool_comp.cursor_mode_tool,'CData',icon.del_lay ,'TooltipString','Delete Layer','ClickedCallback',{@delete_layer_callback,main_figure,[]});


setappdata(main_figure,'Cursor_mode_tool',cursor_mode_tool_comp);

end



function set_curr_disp_mode(src,~,main_figure)

curr_disp=get_esp3_prop('curr_disp');

if strcmp(src.State,'on')
    switch src.Tag
        case 'pan'
           curr_disp.CursorMode='Pan';
        case 'nor'
            curr_disp.CursorMode='Normal';
        case 'bt'
            curr_disp.CursorMode='Bad Pings';
        case 'zout'
            curr_disp.CursorMode='Zoom Out';
        case 'zin'
            curr_disp.CursorMode='Zoom In';
        case {'ed_bot','ed_bot_spline','erase_soundings','ed_bot_sup'}
            curr_disp.CursorMode='Edit Bottom';
        case 'meas'
            curr_disp.CursorMode='Measure';
        case {'create_reg_rect' 'create_reg_poly' 'create_reg_hd' 'create_reg_vert' 'create_reg_horz'}
            curr_disp.CursorMode='Create Region';

    end
else
    curr_disp.CursorMode='Normal';
end



end









