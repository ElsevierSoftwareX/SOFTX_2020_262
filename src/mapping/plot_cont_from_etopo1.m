function [h_c,h_t]=plot_cont_from_etopo1(ax,dl)          
h_c=[];
h_t=[];
LatLim=ax.LatitudeLimits;
LonLim=ax.LongitudeLimits;

if isempty(dl)
    dl=1000;
end

[lat_c,lon_c,bathy]=get_etopo1(LatLim ,LonLim);

max_size=10*60;

dlat=ceil(numel(lat_c)/max_size);
dlon=ceil(numel(lon_c)/max_size);

lat_c=lat_c(1:dlat:end);
lon_c=lon_c(1:dlon:end);
bathy=bathy(1:dlat:end,1:dlon:end);

if length(lon_c)>=2&&length(lat_c)>=2
    
    L=floor(nanmin(bathy(:))/dl)*dl:dl:0;
    %L=floor(nanmin(bathy(:))/dl)*dl:dl:ceil(nanmax(bathy(:))/dl)*dl;
    C=contourc(lon_c,lat_c,double(bathy),double(L));
    [c_out,l_out]=contour_to_cells(C,L);
    
    
    h_c=cellfun(@(x) geoplot(ax,x(2,:),x(1,:),'color',[0.4 0.4 0.4]),c_out);
    h_t=cellfun(@(x,y) text(ax,x(2,ceil(numel(x(2,:))/2)),x(1,ceil(numel(x(1,:))/2)),sprintf('%.0fm',y),'color',[0.4 0.4 0.4],'HorizontalAlignment','left'),c_out(l_out~=0),num2cell(-l_out(l_out~=0)));
    
end