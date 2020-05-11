function listenDispUnderBot(src,listdata,main_figure)
main_menu=getappdata(main_figure,'main_menu');
set(main_menu.disp_under_bot,'checked',listdata.AffectedObject.DispUnderBottom);

switch listdata.AffectedObject.DispUnderBottom
    case 'off'
        main_figure.Alphamap(2)=1-listdata.AffectedObject.UnderBotTransparency/100;
    case 'on'
        main_figure.Alphamap(2)=1;
end

end