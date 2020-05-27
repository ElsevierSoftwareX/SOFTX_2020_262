function order_stacks_fig(main_figure,curr_disp)

mini_axes_comp=getappdata(main_figure,'Mini_axes');
axes_panel_comp=getappdata(main_figure,'Axes_panel');
if isempty(curr_disp)
    curr_disp=get_esp3_prop('curr_disp');
end

switch curr_disp.CursorMode
    case {'Normal' 'Create Region'}
        bt_on_top=0;
    otherwise
        bt_on_top=1;
end
order_stack(axes_panel_comp.main_axes,'bt_on_top',bt_on_top);

order_stack(mini_axes_comp.mini_ax);
end