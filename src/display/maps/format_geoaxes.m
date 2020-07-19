function format_geoaxes(gax)

for iax=1:numel(gax)
    gax(iax).NextPlot='add';
    gax(iax).Box='on';
    gax(iax).MapCenterMode='manual';
    gax(iax).Toolbar=[];

    if will_it_work([],9.7,true)
        gax(iax).LongitudeLabel=matlab.graphics.primitive.Text;
        gax(iax).LatitudeLabel=matlab.graphics.primitive.Text;
    end
    if will_it_work([],9.8,true)
        enableDefaultInteractivity(gax(iax));
        gax(iax).Interactions=[panInteraction zoomInteraction];
    end
    gax(iax).FontSize=8;
end