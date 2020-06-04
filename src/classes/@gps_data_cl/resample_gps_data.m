function obj=resample_gps_data(gps_obj,time)

if ~isempty(gps_obj.Lat)
    if iscolumn(time)
        time=time';
    end
    lat=resample_data_v2(gps_obj.Lat,gps_obj.Time,time,'Type','Angle');
    long=resample_data_v2(gps_obj.Long,gps_obj.Time,time,'Type','Angle');    

    corr_max_lat = 2*prctile(abs(diff(gps_obj.Lat)),99);
    corr_max_lon = 2*prctile(abs(diff(gps_obj.Long)),99);
    
    idx_nan_before = find(time<gps_obj.Time(1)); 
    idx_nan_after = find(time>gps_obj.Time(end));

    
    if ~isempty(idx_nan_before)
        idx_nan_before = idx_nan_before(abs(lat(idx_nan_before)-gps_obj.Lat(1))>corr_max_lat.*(idx_nan_before(end)-idx_nan_before+1)|...
            abs(long(idx_nan_before)-gps_obj.Long(1))>corr_max_lon.*(idx_nan_before(end)-idx_nan_before+1));
    end
    
    if ~isempty(idx_nan_after)
        idx_nan_after = idx_nan_after(abs(lat(idx_nan_after)-gps_obj.Lat(end))>corr_max_lat.*(idx_nan_after(end)-idx_nan_after+1)|...
            abs(long(idx_nan_after)-gps_obj.Long(end))>corr_max_lon.*(idx_nan_after(end)-idx_nan_after+1));
    end
    
    idx_nan = union(idx_nan_before,idx_nan_after);
     
    lat(idx_nan)=nan;
    long(idx_nan)=nan;
    
    nmea=gps_obj.NMEA;
    
    if nansum((size(long)==size(time)))<2
        time=time';
    end
    
    if nansum(isnan(lat))<length(lat) && ~isempty(lat)
        if nansum(~isnan(lat))<length(lat)
            warning('Issue with navigation data... No position for every pings');
        end
        obj=gps_data_cl('Lat',lat,'Long',long,'Time',time,'NMEA',nmea);
    else
        warning('Issue with navigation data...')
        obj=gps_data_cl('Time',time);
    end
else
    obj=gps_data_cl('Time',time);
end


end