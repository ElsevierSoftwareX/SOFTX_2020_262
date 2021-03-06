function go_to_ping(idx_ping,main_figure)

layer=get_current_layer();

if isempty(layer)
    return;
end

axes_panel_comp=getappdata(main_figure,'Axes_panel');
ah=axes_panel_comp.main_axes;


curr_disp=get_esp3_prop('curr_disp');

[trans_obj,idx_freq]=layer.get_trans(curr_disp);

xdata=trans_obj.get_transceiver_pings();

x_lim=[xdata(idx_ping) xdata(idx_ping)+diff(get(ah,'XLim'))];

if any(x_lim>xdata(end))
    x_lim=[xdata(end)-diff(get(ah,'XLim')) xdata(end)];
end

if diff(x_lim)<=0
    return;
end

set(ah,'XLim',x_lim,'YLim',get(ah,'YLim'));


end