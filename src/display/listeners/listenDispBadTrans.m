function listenDispBadTrans(src,listdata,main_figure)
if ~isdeployed()
   disp('listenDispBadTrans') ;
end
main_menu=getappdata(main_figure,'main_menu');
set(main_menu.disp_bad_trans,'checked',listdata.AffectedObject.DispBadTrans);

switch listdata.AffectedObject.DispBadTrans
    case 'off'
        main_figure.Alphamap(3)=0;
    case 'on'
        main_figure.Alphamap(3)=0.7;
end

end