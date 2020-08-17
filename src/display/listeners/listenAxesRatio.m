function listenAxesRatio(src,~,main_figure)
curr_disp=get_esp3_prop('curr_disp');
[echo_obj,~,~,~]=get_axis_from_cids(main_figure,{'main'});

echo_obj.set_axes_position(curr_disp.V_axes_ratio,curr_disp.H_axes_ratio);
end