function [x,y,idx_ping,idx_r] = get_main_ax_cp(echo_obj,trans_obj)

idx_ping = [];
idx_r = [];

cp = echo_obj.main_ax.CurrentPoint;
x = cp(1,1);
y = cp(1,2);

x_lim=get(echo_obj.main_ax,'xlim');
y_lim=get(echo_obj.main_ax,'ylim');

if x<x_lim(1)||x>x_lim(end)||y<y_lim(1)||y>y_lim(end)
   return; 
end

switch echo_obj.echo_usrdata.geometry_x
    case 'pings'
        xdata=trans_obj.get_transceiver_pings();
    case 'seconds'
        xdata=trans_obj.get_transceiver_time();       
    case 'meters'
        xdata=trans_obj.GPSDataPing.Dist;
end

[~,idx_ping] = nanmin(abs(xdata-x));

switch echo_obj.echo_usrdata.geometry_y
    case 'samples'
        ydata = trans_obj.get_transceiver_samples();
    case 'depth'
        ydata=get_transceiver_depth(trans_obj,[],idx_ping);
    case 'range'
        ydata=get_transceiver_range(trans_obj,[],idx_ping);
end

[~,idx_r] = nanmin(abs(ydata-y));