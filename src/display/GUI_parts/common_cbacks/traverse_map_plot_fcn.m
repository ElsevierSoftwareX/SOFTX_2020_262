function traverse_map_plot_fcn(src,evt,hplot)
set(src, 'Pointer', 'hand');
% ax=ancestor(hplot,'geoaxes');
% cp=ax.CurrentPoint;
% objt=findobj(ax,'Tag','tooltipt');
% xlim=get(ax,'XLim');
% dx=diff(xlim)/1e2;
% 
% if isempty(objt)
%     text(ax,cp(1,1)+dx,cp(1,2),hplot.UserData.txt,'Tag','tooltipt','EdgeColor','k','BackgroundColor','y','VerticalAlignment','Bottom','Interpreter','none');
% else
%     set(objt,'Position',[cp(1,1)+dx,cp(1,2)],'String',hplot.UserData.txt);
% end
% obj=findobj(ax,'Tag','tooltip');
% if isempty(obj)
% 
%     plot(ax,cp(1,1),cp(1,2),'Marker','o','MarkerEdgeColor','r','MarkerFaceColor','k','MarkerSize',6,'Tag','tooltip');
% else
%      set(obj,'XData',cp(1,1),'YData',cp(1,2));
% end
end
