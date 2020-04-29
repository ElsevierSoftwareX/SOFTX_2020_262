function dist_in_km = lat_long_to_km(lat,lon)

nb_pt = numel(lat);

if isrow(lat)
    lat=lat';
end

if isrow(lon)
    lon=lon';
end

try
    dist_in_deg = distance([lat(1:nb_pt-1) lon(1:nb_pt-1)],[lat(2:nb_pt) lon(2:nb_pt)]);
    dist_in_km  = deg2km(dist_in_deg);
    dist_in_km=dist_in_km';
catch err
    print_errors_and_warnings([],'warning',err); 
    dist_in_km=zeros(1,numel(lat)-1);
end
