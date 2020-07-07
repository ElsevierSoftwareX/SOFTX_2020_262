function [dist_km,timediff_h]=get_tot_dist_and_time_diff(gps_obj,idx_good)

if isempty(idx_good)
    idx_good=1:length(gps_obj.Long);
end

idx_good=intersect(idx_good,find(~isnan(gps_obj.Long)));

dist_km=sum(lat_long_to_km(gps_obj.Lat(idx_good),gps_obj.Long(idx_good)));
timediff_h=(gps_obj.Time(idx_good(end))-gps_obj.Time(idx_good(1)))*24;

end