function id_screen=get_fig_screen_id(main_figure)

size_max = get(groot, 'MonitorPositions');
units= get(groot ,'units');

if isempty(main_figure)
    [~,id_screen]=max(size_max(:,3));
else
    switch units
        case 'normalized'
            pos_main=main_figure.Position;
        otherwise            
            pos_main=getpixelposition(main_figure);
    end
[~,id_screen]=nanmin(abs(size_max(:,1)-pos_main(1)));
end