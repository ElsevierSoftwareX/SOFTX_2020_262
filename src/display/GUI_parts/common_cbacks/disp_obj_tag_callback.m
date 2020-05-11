function disp_obj_tag_callback(src,evt)

ax=get(src,'parent');
hfig=ancestor(ax,'Figure');

cp=evt.IntersectionPoint;
x = cp(1,1);
y=cp(1,2);

switch hfig.SelectionType
    case 'normal'
        str=src.UserData.txt;
        u = findobj(ax,'Tag','name');
        delete(u);
        plot(ax,x,y,'o','markeredgecolor','r','markerfacecolor','k','Tag','name');
        text(ax,x,y,str,'Interpreter','None','Tag','name','EdgeColor','k','BackgroundColor','w','VerticalAlignment','bottom','Clipping','on');
    case {'open' 'alt'}
        u = findobj(ax,'Tag','name');
        delete(u);
end
end
