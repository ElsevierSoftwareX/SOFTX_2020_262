function display_file_lines(main_figure)
main_menu=getappdata(main_figure,'main_menu');
axes_panel_comp=getappdata(main_figure,'Axes_panel');
curr_disp=get_esp3_prop('curr_disp');
layer=get_current_layer();

[trans_obj,idx_freq]=layer.get_trans(curr_disp);

[cmap,col_ax,col_lab,col_grid,col_bot,col_txt,col_tracks]=init_cmap(curr_disp.Cmap);


idx_change_file=find(diff(trans_obj.Data.FileId)>0);

state_file_lines=get(main_menu.display_file_lines,'checked');

xdata=trans_obj.get_transceiver_pings();

obj_line=findobj(axes_panel_comp.main_axes,'Tag','file_id');
delete(obj_line);

for ifile=1:length(idx_change_file)
    %plot(axes_panel_comp.main_axes,xdata(idx_change_file(ifile)).*ones(size(ydata))+1/2,ydata,'color',col_lab,'Tag','file_id');
    xline(axes_panel_comp.main_axes,xdata(idx_change_file(ifile))+1/2,'color',col_lab,'Tag','file_id','Label',layer.Filename{ifile},'Interpreter','none');
end

obj_line=findobj(axes_panel_comp.main_axes,'Tag','file_id');

for i=1:length(obj_line)
    set(obj_line(i),'vis',state_file_lines); 
end

end
