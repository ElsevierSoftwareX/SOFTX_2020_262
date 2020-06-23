function toggle_disp_lines(main_figure)

axes_panel_comp=getappdata(main_figure,'Axes_panel');
curr_disp=get_esp3_prop('curr_disp');

main_axes=axes_panel_comp.echo_obj.main_ax;

u=findobj(main_axes,'tag','lines');

set(u,'visible',curr_disp.DispLines);


end
