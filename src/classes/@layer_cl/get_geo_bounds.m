function [latLim,lonLim]=get_geo_bounds(layer_obj)

p = inputParser;
addRequired(p,'layer_obj',@(obj) isa(obj,'layer_cl'));

parse(p,layer_obj);
latLim=[-90 90];
lonLim=[-180 180];

if ~isempty(layer_obj)
    if ~isempty(layer_obj.GPSData.Lat)
        latLim=[nanmin(layer_obj.GPSData.Lat) nanmax(layer_obj.GPSData.Lat)];
        lonLim=[nanmin(layer_obj.GPSData.Long) nanmax(layer_obj.GPSData.Long)];
    end
end


end