function reverse_y_axis(main_figure)
main_menu=getappdata(main_figure,'main_menu');
axes_panel_comp=getappdata(main_figure,'Axes_panel');

reverse_y_axis_state=get(main_menu.reverse_y_axis,'checked');

switch reverse_y_axis_state
    case 'off'
        set(axes_panel_comp.echo_obj.main_ax,'YDir','reverse');
    case 'on'
        set(axes_panel_comp.echo_obj.main_ax,'YDir','normal');
end

