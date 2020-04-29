function listenCursorMode(~,listdata,main_figure)
%profile on;
if~isdeployed
    disp('ListenCursorMode')
end
cursor_mode_tool_comp=getappdata(main_figure,'Cursor_mode_tool');

if isappdata(main_figure,'Axes_panel')
    axes_panel_comp=getappdata(main_figure,'Axes_panel');
    ah=axes_panel_comp.main_axes;
    clear_lines_temp(ah);
    select_area=getappdata(main_figure,'SelectArea');
    delete(select_area.patch_h);
    delete(select_area.uictxt_menu_h);
    select_area.patch_h=[];
    select_area.uictxt_menu_h=[];
    setappdata(main_figure,'SelectArea',select_area);
    
end

switch listdata.AffectedObject.CursorMode
    case 'Zoom In'
        toggle_func(cursor_mode_tool_comp.zoom_in,[],main_figure);
    case 'Zoom Out'
        toggle_func(cursor_mode_tool_comp.zoom_out,[],main_figure);
    case 'Bad Transmits'
        toggle_func(cursor_mode_tool_comp.bad_trans,[],main_figure);
    case 'Add ST'
        toggle_func('add_st',[],main_figure);
    case 'Edit Bottom'
        toggle_func(cursor_mode_tool_comp.edit_bottom,[],main_figure);
    case 'Measure'
        toggle_func(cursor_mode_tool_comp.measure,[],main_figure);
    case 'Create Region'
        toggle_func(cursor_mode_tool_comp.create_reg,[],main_figure);
    case 'Draw Line'
        toggle_func('draw_line',[],main_figure);
     case 'Pan'
        toggle_func(cursor_mode_tool_comp.pan,[],main_figure);
    case 'Normal'
        toggle_func(cursor_mode_tool_comp.pointer,[],main_figure);
end
%order_axes(main_figure);
%profile off;
%profile viewer;
end