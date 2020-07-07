function update_grid_mini_ax(main_figure)

layer=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');
mini_axes_comp=getappdata(main_figure,'Mini_axes');

if ~isgraphics(mini_axes_comp.echo_obj.main_ax.Parent,'figure')
    return;
end

[trans_obj,~]=layer.get_trans(curr_disp);
if isempty(trans_obj)
return;
end
xdata=get(mini_axes_comp.echo_obj.echo_surf,'XData');
ydata=get(mini_axes_comp.echo_obj.echo_surf,'YData');

idx_pings=ceil(mini_axes_comp.echo_obj.echo_surf.XData);
idx_r=ceil(mini_axes_comp.echo_obj.echo_surf.YData);

curr_disp.init_grid_val(trans_obj);
[dx,dy]=curr_disp.get_dx_dy();

switch curr_disp.Xaxes_current
    case 'seconds'
            xdata_grid=trans_obj.Time(idx_pings);
            xdata_grid=xdata_grid*(24*60*60);
    case 'pings'
        xdata_grid=trans_obj.get_transceiver_pings(idx_pings);
    case 'meters'
        xdata_grid=trans_obj.GPSDataPing.Dist(idx_pings);
        if isempty(xdata)
            disp_perso(main_figure,'NO GPS Data');
            curr_disp.Xaxes_current='pings';
            xdata_grid=trans_obj.get_transceiver_pings(idx_pings);
        end
    otherwise
        xdata_grid=trans_obj.get_transceiver_pings(idx_pings);      
end

ydata_grid=trans_obj.get_transceiver_range(idx_r);
 

idx_xticks=find((diff(rem(xdata_grid,dx))<0))+1;
idx_yticks=find((diff(rem(ydata_grid,dy))<0))+1;

set(mini_axes_comp.echo_obj.main_ax,'XTick',xdata(idx_xticks),'YTick',ydata(idx_yticks),'XAxisLocation','top','XGrid','on','YGrid','on');

end