function update_grid(main_figure)

layer=get_current_layer();
axes_panel_comp=getappdata(main_figure,'Axes_panel');
curr_disp=get_esp3_prop('curr_disp');

[trans_obj,~]=layer.get_trans(curr_disp);
if isempty(trans_obj)
    return;
end
% profile on;

try
    
    idx_pings=round(axes_panel_comp.main_echo.XData);
    idx_r=round(axes_panel_comp.main_echo.YData);
    curr_disp=init_grid_val(main_figure);
    [dx,dy]=curr_disp.get_dx_dy();
    
    switch curr_disp.Xaxes_current
        case 'seconds'
            xdata_grid=trans_obj.Time(idx_pings);
            xdata_grid=xdata_grid*(24*60*60);
        case 'pings'
            xdata_grid=trans_obj.get_transceiver_pings(idx_pings);
        case 'meters'
            xdata_grid=trans_obj.GPSDataPing.Dist;
            if  ~any(~isnan(trans_obj.GPSDataPing.Lat))
                disp('No GPS Data');
                curr_disp.Xaxes_current='pings';
                curr_disp=init_grid_val(main_figure);
                [dx,dy]=curr_disp.get_dx_dy();
                xdata_grid=trans_obj.get_transceiver_pings(idx_pings);
            else
                xdata_grid=xdata_grid(idx_pings);
            end
        otherwise
            xdata_grid=trans_obj.get_transceiver_pings(idx_pings);
    end
    
    
    ydata_grid=trans_obj.get_transceiver_range(idx_r);
    
    
    idx_xticks=find((diff(rem(xdata_grid,dx))<0))+1;
    idx_minor_xticks=find((diff(rem(xdata_grid+dx/2,dx))<0))+1;
    
    idx_yticks=find((diff(rem(ydata_grid,dy))<0))+1;
    idx_minor_yticks=find((diff(rem(ydata_grid+dy/2,dy))<0))+1;
    
    
    idx_minor_xticks=setdiff(idx_minor_xticks,idx_xticks);
    idx_minor_yticks=setdiff(idx_minor_yticks,idx_yticks);
    
    axes_panel_comp.main_axes.XTick=idx_pings(idx_xticks);
    axes_panel_comp.main_axes.YTick=idx_r(idx_yticks);
    
    axes_panel_comp.main_axes.XAxis.MinorTickValues=idx_pings(idx_minor_xticks);
    axes_panel_comp.main_axes.YAxis.MinorTickValues=idx_r(idx_minor_yticks);
    
    
    fmt=' %.0fm';
    
    yl=num2cell(floor(ydata_grid(idx_yticks)/dy)*dy);
    y_labels=cellfun(@(x) num2str(x,fmt),yl,'UniformOutput',0);
    
    set(axes_panel_comp.vaxes,'yticklabels',y_labels);
    
    
    str_start=' ';
    xl=num2cell((xdata_grid(idx_xticks)/dx)*dx);
    switch lower(curr_disp.Xaxes_current)
        case 'seconds'
            h_fmt='HH:MM:SS';
            x_labels=cellfun(@(x) datestr(x/(24*60*60),h_fmt),xl,'UniformOutput',0);
        case 'pings'
            fmt=[str_start '%.0f'];
            axes_panel_comp.haxes.XTickLabelMode='auto';
            x_labels=cellfun(@(x) num2str(x,fmt),xl,'UniformOutput',0);
        case 'meters'
            axes_panel_comp.haxes.XTickLabelMode='auto';
            fmt=[str_start '%.0fm'];
            x_labels=cellfun(@(x) num2str(x,fmt),xl,'UniformOutput',0);
        otherwise
            axes_panel_comp.haxes.XTickLabelMode='auto';
            fmt=[str_start '%.0f'];
            x_labels=cellfun(@(x) num2str(x,fmt),xl,'UniformOutput',0);
    end
    
    set(axes_panel_comp.haxes,'xticklabels',x_labels);
    
    
    secondary_freq=getappdata(main_figure,'Secondary_freq');
    
    if isempty(secondary_freq)
        return;
    end
    
    if isempty(secondary_freq.axes)
        return;
    end
    
    if strcmpi(secondary_freq.axes(1).UserData.geometry_y,'depth')
        ylim=get(secondary_freq.axes(1),'Ylim');
        set(secondary_freq.axes,'ytick',floor((ylim(1):curr_disp.Grid_y:ylim(2))/curr_disp.Grid_y)*curr_disp.Grid_y);
        set(secondary_freq.side_ax,'ytick',floor((ylim(1):curr_disp.Grid_y:ylim(2))/curr_disp.Grid_y)*curr_disp.Grid_y);
    end
catch err
    warning('Error while updating grid..');
    print_errors_and_warnings(1,'error',err);
end
% profile off;
% profile viewer;
end