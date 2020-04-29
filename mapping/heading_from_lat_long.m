function heading=heading_from_lat_long(lat,long)

% x = sind(-diff(long)).* cos(lat(2:end));
% y = cosd(lat(1:end-1)).*sind(lat(2:end))-...
%         sind(lat(1:end-1)).*cosd(lat(2:end)).*cosd(-diff(long));
%
% headi = atan2d(x,y);
% headi(headi<0)=headi(headi<0)+360;

if isrow(lat)
    lat=lat';
end

if isrow(long)
    long=long';
end

nb_pt=numel(lat);
try
    [~,heading]=distance([lat(1:nb_pt-1) long(1:nb_pt-1)],[lat(2:nb_pt) long(2:nb_pt)]);
    heading=heading';
catch err
    print_errors_and_warnings([],'warning',err);
    heading=zeros(1,numel(lat)-1);
end

end