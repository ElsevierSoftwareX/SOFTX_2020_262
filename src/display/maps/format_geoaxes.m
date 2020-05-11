function format_geoaxes(gax)

for iax=1:numel(gax)
    gax(iax).NextPlot='add';
    gax(iax).Box='on';
    gax(iax).MapCenterMode='manual';
    gax(iax).Toolbar=[];
    cur_ver=ver('Matlab');
    if str2double(cur_ver.Version)>=9.7
        gax(iax).LongitudeLabel=matlab.graphics.primitive.Text;
        gax(iax).LatitudeLabel=matlab.graphics.primitive.Text;
    end
    if str2double(cur_ver.Version)>=9.8
        enableDefaultInteractivity(gax(iax));
        gax(iax).Interactions=[panInteraction zoomInteraction];
    end
    gax(iax).FontSize=8;
end