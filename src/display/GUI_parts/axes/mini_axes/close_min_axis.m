function close_min_axis(src,~)
main_figure = get_esp3_prop('main_figure');
undock_mini_axes_callback(src,[],main_figure,'main_figure');
end