function order_stacks_fig(main_figure,curr_disp)

mini_axes_comp=getappdata(main_figure,'Mini_axes');
axes_panel_comp=getappdata(main_figure,'Axes_panel');
order_stack(axes_panel_comp.main_axes,'bt_on_top',0);
order_stack(mini_axes_comp.mini_ax);
end