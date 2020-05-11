function [size_fig,units]=get_init_fig_size(main_figure)
units=get(groot,'units');
size_max = get(groot, 'MonitorPositions');

if isempty(main_figure)
    [~,id_screen]=max(size_max(:,3));
else
    pos_main=getpixelposition(main_figure);
   [~,id_screen]=nanmin(abs(size_max(:,1)-pos_main(1))); 
end

%ratio=size_max(id_screen,3)/size_max(id_screen,4);

dr=4/5;

size_fig=[0 0 size_max(id_screen,3)*dr size_max(id_screen,4)*dr];

end