function listenDispSpikes(src,listdata,main_figure)
main_menu=getappdata(main_figure,'main_menu');

set(main_menu.disp_spikes,'checked',listdata.AffectedObject.DispSpikes);

switch listdata.AffectedObject.DispSpikes
    case 'off'
        main_figure.Alphamap(5)=0;
    case 'on'
        main_figure.Alphamap(5)=1;
end

end