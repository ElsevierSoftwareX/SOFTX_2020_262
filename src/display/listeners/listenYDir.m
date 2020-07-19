function listenYDir(src,listdata,main_figure)

axes_panel_comp=getappdata(main_figure,'Axes_panel');

set(axes_panel_comp.echo_obj.main_ax,'YDir',listdata.AffectedObject.YDir);


end