function toggle_display_file_lines(main_figure)
main_menu=getappdata(main_figure,'main_menu');
axes_panel_comp=getappdata(main_figure,'Axes_panel');
curr_disp=get_esp3_prop('curr_disp');
[cmap,col_ax,col_lab,col_grid,col_bot,col_txt,~]=init_cmap(curr_disp.Cmap);
state_file_lines=get(main_menu.display_file_lines,'checked');

obj_line=findobj(axes_panel_comp.echo_obj.main_ax,'Tag','file_id');

set(obj_line,'vis',state_file_lines,'color',col_lab);


end
