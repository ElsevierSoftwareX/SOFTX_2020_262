function axes_panel_comp=display_tracks(main_figure)
axes_panel_comp=getappdata(main_figure,'Axes_panel');
track_h=findobj(axes_panel_comp.echo_obj.main_ax,'tag','track');

delete(track_h);

delete(findobj(ancestor(axes_panel_comp.echo_obj.main_ax,'figure'),'Type','UiContextMenu','-and','Tag','stTrackCtxtMenu'));

objt=findobj(axes_panel_comp.echo_obj.main_ax,'Tag','tooltipt');
delete(objt);

layer=get_current_layer();

curr_disp=get_esp3_prop('curr_disp');
[~,~,~,~,~,~,col_tracks]=init_cmap(curr_disp.Cmap);
[trans_obj,idx_freq]=layer.get_trans(curr_disp);

ST=trans_obj.ST;
tracks=trans_obj.Tracks;
xdata=trans_obj.get_transceiver_pings();

X_st=xdata(ST.Ping_number);
Z_st=ST.idx_r;


if isempty(tracks)
    return;
end

if isempty(tracks.target_id)
    return;
end

xd=get(axes_panel_comp.echo_obj.echo_surf,'XData');
x_lim=[nanmin(xd(:)) nanmax(xd(:))];
idx_remove=find(cellfun(@(x) all(x<x_lim(1)|x>x_lim(2)),tracks.target_ping_number));
tracks.id(idx_remove)=[];
tracks.uid(idx_remove)=[];
tracks.target_id(idx_remove)=[];
tracks.target_ping_number(idx_remove)=[];

for k=1:length(tracks.target_id)
    idx_targets=tracks.target_id{k};
    [X_t,idx_sort]=sort(X_st(idx_targets));
    Z_t=Z_st(idx_targets);
    Z_t=Z_t(idx_sort);

    plot_handle=plot(axes_panel_comp.echo_obj.main_ax,X_t,Z_t,'linewidth',0.7,'tag','track','visible',curr_disp.DispTracks,'userdata',tracks.uid{k},'Color',col_tracks,'Color',col_tracks);
    
    pointerBehavior.enterFcn    = @(src, evt) enter_track_plot_fcn(src, evt,plot_handle);
    pointerBehavior.exitFcn     = @(src, evt) exit_track_plot_fcn(src, evt,plot_handle);
    pointerBehavior.traverseFcn = [];
    
    iptSetPointerBehavior(plot_handle,pointerBehavior);
    create_context_menu_st_track(main_figure,plot_handle);
    
end


end
function exit_track_plot_fcn(src,~,hplot)
if ~isvalid(hplot)
    delete(hplot);
    return;
end
% set(src, 'Pointer', 'hand');
ax=ancestor(hplot,'axes');
objt=findobj(ax,'Tag','tooltipt');
delete(objt);
% obj=findobj(ax,'Tag','tooltip');
% delete(obj);
set(hplot,'linewidth',0.7);

end

function enter_track_plot_fcn(src,evt,hplot)
if ~isvalid(hplot)
    delete(hplot);
    return;
end
main_figure=ancestor(hplot,'figure');
layer=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');
set(src, 'Pointer', 'hand');
ax=ancestor(hplot,'axes');
set(hplot,'linewidth',2);
cp=ax.CurrentPoint;
objt=findobj(ax,'Tag','tooltipt');
xlim=get(ax,'XLim');
dx=diff(xlim)/1e2;
[trans_obj,~]=layer.get_trans(curr_disp);

tracks=trans_obj.Tracks;

id=tracks.id(strcmp(tracks.uid,hplot.UserData));
%
if isempty(objt)
    text(ax,cp(1,1)+dx,cp(1,2),sprintf('Track %d',id),'Tag','tooltipt','EdgeColor','k','BackgroundColor',[1 1 0.8],'VerticalAlignment','Bottom','Interpreter','none');
else
    set(objt,'Position',[cp(1,1)+dx,cp(1,2)],'String',sprintf('Track %d',id));
end
% obj=findobj(ax,'Tag','tooltip');
% if isempty(obj)
%
%     plot(ax,cp(1,1),cp(1,2),'Marker','o','MarkerEdgeColor','r','MarkerFaceColor','k','MarkerSize',6,'Tag','tooltip');
% else
%      set(obj,'XData',cp(1,1),'YData',cp(1,2));
% end
end


