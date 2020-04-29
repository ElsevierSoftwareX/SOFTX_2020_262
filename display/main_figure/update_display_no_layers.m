function update_display_no_layers(main_figure)

obj_enable=findobj(main_figure,'Enable','on','-not',{'Type','uimenu','-or','Type','uitable'});
set(obj_enable,'Enable','off');

axes_panel_comp=getappdata(main_figure,'Axes_panel');
delete(axes_panel_comp.axes_panel);
rmappdata(main_figure,'Axes_panel');

mini_axes_comp=getappdata(main_figure,'Mini_axes');
delete(mini_axes_comp.mini_ax);
rmappdata(main_figure,'Mini_axes');

if isappdata(main_figure,'Secondary_freq')
    sec_freq=getappdata(main_figure,'Secondary_freq');
    delete(sec_freq.fig);
    rmappdata(main_figure,'Secondary_freq');
end

update_multi_freq_disp_tab(main_figure,'sv_f',1);
update_multi_freq_disp_tab(main_figure,'ts_f',1);
update_reglist_tab(main_figure,0);
update_tree_layer_tab(main_figure);

end