function update_cmap(main_figure)
% profile on
axes_panel_comp=getappdata(main_figure,'Axes_panel');

curr_disp=get_esp3_prop('curr_disp');
layer=get_current_layer();
mini_axes_comp=getappdata(main_figure,'Mini_axes');
%st_tracks_tab_comp=getappdata(main_figure,'ST_Tracks');
echo_int_tab_comp=getappdata(main_figure,'EchoInt_tab');

if isempty(axes_panel_comp)
    return;
end
[cmap,col_ax,col_lab,col_grid,col_bot,col_txt,col_tracks]=init_cmap(curr_disp.Cmap);

set(axes_panel_comp.main_axes,'Color',col_ax,...
    'GridColor',col_grid,'MinorGridColor',col_grid,'XColor',col_lab,'YColor',col_lab);

[~,~,echo_im_bt,~,~,~]=get_axis_from_cids(main_figure,union({'main' 'mini'}, layer.ChannelID));

for iim=1:numel(echo_im_bt)
    set(echo_im_bt(iim),'FaceColor',col_lab);
end

set(axes_panel_comp.bottom_plot,'Color',col_bot);
    track_h=findobj(axes_panel_comp.main_axes,'tag','track');
set(track_h,'Color',col_tracks);

lines_obj=findobj(axes_panel_comp.main_axes,'tag','lines');
set(lines_obj,'Color',col_tracks);

set(mini_axes_comp.bottom_plot,'Color',col_bot);
obj_line=findobj(axes_panel_comp.main_axes,'Tag','file_id');
set(obj_line,'Color',col_lab);

txt_obj=[findobj(axes_panel_comp.main_axes,'Type','Text','-not',{'Tag','lines','-or','Tag','tooltipl'});
    findobj(mini_axes_comp.mini_ax,'Type','Text','-not','Tag','lines','-not',{'Tag','lines','-or','Tag','tooltipl'});...
    findobj(axes_panel_comp.vaxes,'Type','Text','-not','Tag','lines','-not',{'Tag','lines','-or','Tag','tooltipl'})];
mini_axes_comp.patch_lim_obj.EdgeColor=col_bot;
set(txt_obj,'Color',col_txt);

txt_obj=findobj(axes_panel_comp.main_axes,'Type','Text','-and','Tag','tooltipl');
set(txt_obj,'Color',col_txt,'EdgeColor',col_txt,'BackgroundColor',col_ax);

set(axes_panel_comp.v_bot_val,'color',col_grid);



set(axes_panel_comp.main_axes,'Color',col_ax,...
    'GridColor',col_grid,'MinorGridColor',col_grid,'XColor',col_lab,'YColor',col_lab);


% set(st_tracks_tab_comp.ax_pos,'Color',col_ax,...
%     'GridColor',col_grid,'MinorGridColor',col_grid,'XColor',col_lab,'YColor',col_lab);
% set(st_tracks_tab_comp.ax_pdf,'Color',col_ax,...
%     'GridColor',col_grid,'MinorGridColor',col_grid,'XColor',col_lab,'YColor',col_lab);

% colormap(st_tracks_tab_comp.ax_pdf,cmap);
% colormap(st_tracks_tab_comp.ax_pos,cmap);


colormap(mini_axes_comp.mini_ax,cmap);
colormap(axes_panel_comp.main_axes,cmap);
update_st_tracks_tab(main_figure);
colormap(echo_int_tab_comp.main_ax,cmap);

if isappdata(main_figure,'Secondary_freq')&&curr_disp.DispSecFreqs>0
    secondary_freq=getappdata(main_figure,'Secondary_freq');
    
    colormap(secondary_freq.fig,cmap);
    set(secondary_freq.bottom_plots,'color',col_bot);
    set(secondary_freq.names,'color',col_txt); 
end

update_regions_colors(main_figure,'all');
%format_color_gui(getappdata(main_figure,'ExternalFigures'),curr_disp.Font,curr_disp.Cmap);
format_color_gui(main_figure,curr_disp.Font,curr_disp.Cmap);
%profile off;
%profile viewer;
end