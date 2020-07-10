function listenDispColorbar(src,~,main_figure)
curr_disp=get_esp3_prop('curr_disp');
[echo_obj,~,~,~]=get_axis_from_cids(main_figure,{'main'});
if isempty(echo_obj.colorbar_h)
    return;
end
if strcmpi(echo_obj.colorbar_h.Visible,'on')
    echo_obj.colorbar_h.Visible = 'off';
else
    echo_obj.colorbar_h.Visible = 'on';
end
echo_obj.set_axes_position(curr_disp.V_axes_ratio,curr_disp.H_axes_ratio);
end