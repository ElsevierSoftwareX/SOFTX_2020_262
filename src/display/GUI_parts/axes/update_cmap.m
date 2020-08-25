function update_cmap(main_figure)
% profile on
axes_panel_comp=getappdata(main_figure,'Axes_panel');

curr_disp=get_esp3_prop('curr_disp');
layer=get_current_layer();
mini_axes_comp=getappdata(main_figure,'Mini_axes');
%st_tracks_tab_comp=getappdata(main_figure,'ST_Tracks');

if isempty(axes_panel_comp)
    return;
end
[cmap,col_ax,col_lab,col_grid,col_bot,col_txt,col_tracks]=init_cmap(curr_disp.Cmap);

set(axes_panel_comp.echo_obj.main_ax,'Color',col_ax,...
    'GridColor',col_grid,'MinorGridColor',col_grid,'XColor',col_lab,'YColor',col_lab);

[echo_obj,~,~,~]=get_axis_from_cids(main_figure,union({'main' 'mini'}, layer.ChannelID));

for iim=1:numel(echo_obj)
    set(echo_obj.get_echo_bt_surf(iim),'FaceColor',col_lab);
end

set(axes_panel_comp.echo_obj.bottom_line_plot,'Color',col_bot);
    track_h=findobj(axes_panel_comp.echo_obj.main_ax,'tag','track');
set(track_h,'Color',col_tracks);

lines_obj=findobj(axes_panel_comp.echo_obj.main_ax,'tag','lines');
set(lines_obj,'Color',col_tracks);

set(mini_axes_comp.echo_obj.bottom_line_plot,'Color',col_bot);
obj_line=findobj(axes_panel_comp.echo_obj.main_ax,'Tag','file_id');
set(obj_line,'Color',col_lab);

txt_obj=[findobj(axes_panel_comp.echo_obj.main_ax,'Type','Text','-not',{'Tag','lines','-or','Tag','tooltipl'});
    findobj(mini_axes_comp.echo_obj.main_ax,'Type','Text','-not','Tag','lines','-not',{'Tag','lines','-or','Tag','tooltipl'});...
    findobj(axes_panel_comp.echo_obj.vert_ax,'Type','Text','-not','Tag','lines','-not',{'Tag','lines','-or','Tag','tooltipl'})];
mini_axes_comp.patch_lim_obj.EdgeColor=col_bot;
set(txt_obj,'Color',col_txt);

txt_obj=findobj(axes_panel_comp.echo_obj.main_ax,'Type','Text','-and','Tag','tooltipl');
set(txt_obj,'Color',col_txt,'EdgeColor',col_txt,'BackgroundColor',col_ax);

set(axes_panel_comp.v_bot_val,'color',col_grid);

set(axes_panel_comp.echo_obj.main_ax,'Color',col_ax,...
    'GridColor',col_grid,'MinorGridColor',col_grid,'XColor',col_lab,'YColor',col_lab);


axes_panel_comp.echo_obj.main_ax.Colormap = cmap;

update_st_tracks_tab(main_figure);

if isappdata(main_figure,'Secondary_freq')&&curr_disp.DispSecFreqs>0
    secondary_freq=getappdata(main_figure,'Secondary_freq');
    
    colormap(secondary_freq.fig,cmap);
    set(secondary_freq.echo_obj.get_bottom_line_plot(),'color',col_bot);
    set(secondary_freq.names,'color',col_txt); 
end


if isappdata(main_figure,'wc_fan')
    wc_fan  = getappdata(main_figure,'wc_fan');
    wc_fan.wc_axes.Color = col_ax;
    wc_fan.wc_axes.GridColor = col_grid;
    wc_fan.wc_axes.MinorGridColor = col_grid;
    wc_fan.wc_axes.XColor = col_lab;
    wc_fan.wc_axes.YColor = col_lab;
    wc_fan.wc_fan_fig.Color = col_ax;
    wc_fan.wc_axes_tt.BackgroundColor = col_ax;
    wc_fan.wc_axes_tt.ForegroundColor = col_lab;
    wc_fan.wc_fig.Colormap=cmap;
    wc_fan.wc_axes.Colormap=cmap;
    wc_fan.wc_cbar.Color = col_lab;
end


update_regions_colors(main_figure,'all');
%format_color_gui(getappdata(main_figure,'ExternalFigures'),curr_disp.Font,curr_disp.Cmap);
format_color_gui(main_figure,curr_disp.Font,curr_disp.Cmap);
%profile off;
%profile viewer;
end