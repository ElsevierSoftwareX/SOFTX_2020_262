function attitude_heading=att_heading_from_gps(gps_data_obj,dt)

attitude_heading=attitude_nav_cl().empty;

n=ceil(dt/(nanmean(diff(gps_data_obj.Time))*24*60*60));
n=nanmin(n,numel(gps_data_obj.Lat)-1);

if n>0
    heading_g=heading_from_lat_long(gps_data_obj.Lat(1:n:end),gps_data_obj.Long(1:n:end));
    th=gps_data_obj.Time(1:n:end);
    th=th+nanmean(diff(th))/2;
    th=th(1:numel(heading_g));
    attitude_heading=attitude_nav_cl('Heading',heading_g,'Time',th);
    attitude_heading.NMEA_heading=sprintf('Extrapolated Lat/Lon(%s)',gps_data_obj.NMEA);
end

end