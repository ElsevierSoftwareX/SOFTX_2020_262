function toggle_disp_tracks(main_figure)

axes_panel_comp=getappdata(main_figure,'Axes_panel');

track_h=findobj(axes_panel_comp.main_axes,'tag','track');
set(track_h,'visible',curr_disp.DispTracks);


end

