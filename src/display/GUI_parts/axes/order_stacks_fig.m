function order_stacks_fig(main_figure,curr_disp)


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

axes_panel_comp.echo_obj.order_echo_stack('bt_on_top',bt_on_top);
mini_axes_comp=getappdata(main_figure,'Mini_axes');
mini_axes_comp.echo_obj.order_echo_stack('bt_on_top',0);

end