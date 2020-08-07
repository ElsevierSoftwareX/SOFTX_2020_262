function display_lines(main_figure)

layer=get_current_layer();
%lines_tab_comp=getappdata(main_figure,'Lines_tab');
axes_panel_comp=getappdata(main_figure,'Axes_panel');
curr_disp=get_esp3_prop('curr_disp');
[trans_obj,idx_freq]=layer.get_trans(curr_disp);

curr_time=trans_obj.Time;
curr_pings=trans_obj.get_transceiver_pings();

curr_range=trans_obj.get_transceiver_range();
curr_dist=trans_obj.GPSDataPing.Dist;

main_axes=axes_panel_comp.echo_obj.main_ax;

u=findobj(main_axes,'tag','lines');

delete(u);

list_line = layer.list_lines();

if isempty(layer.Lines)
    return;
end

vis=curr_disp.DispLines;

for i=1:length(list_line)
    active_line=layer.Lines(i);

    if nansum(curr_dist)>0&&active_line.Dist_diff~=0
        dist_corr=curr_dist-active_line.Dist_diff;
        time_corr=resample_data_v2(curr_time,curr_dist,dist_corr);
        time_corr(isnan(time_corr))=curr_time(isnan(time_corr))+nanmean(time_corr(:)-curr_time(:));
        
    else
        time_corr=curr_time;
    end
    
    if ~isempty(active_line.Range)
        %profile on;
        y_line=resample_data_v2(active_line.Range,active_line.Time,time_corr,'IgnoreNaNs',0);
        %profile viewer;
        %profile off;
        y_line=ceil(y_line./nanmean(diff(curr_range)))+1/2;
        
        if isempty(y_line)
            warning('Line time does not match the current layer.');
            continue;
        end
        
        x_line=curr_pings;
        [cmap,col_ax,col_lab,col_grid,col_bot,col_txt,col_tracks]=init_cmap(curr_disp.Cmap);
        
        line_plot=plot(main_axes,x_line,y_line,'color',col_tracks,'linewidth',0.5,'tag','lines','visible',vis,'UserData',active_line.ID);
        pointerBehavior.enterFcn    = @(src, evt) enter_line_plot_fcn(src, evt,line_plot);
        pointerBehavior.exitFcn     = @(src, evt) exit_line_plot_fcn(src, evt,line_plot);
        pointerBehavior.traverseFcn = [];
        iptSetPointerBehavior(line_plot,pointerBehavior);
    end
end

end

function exit_line_plot_fcn(src,~,hplot)
set(hplot,'linewidth',0.5);
ax=ancestor(hplot,'axes');
objt=findobj(ax,'Tag','tooltipl');
delete(objt);
end

function enter_line_plot_fcn(src,evt,hplot)

if ~isvalid(hplot)
    delete(hplot);
    return;
end
%main_figure=ancestor(hplot,'figure');
layer=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');
line_idx=layer.get_lines_per_ID(hplot.UserData);

if isempty(line_idx)
    return;
end

line_obj=layer.Lines(line_idx);

[cmap,col_ax,col_lab,col_grid,col_bot,col_txt,col_tracks]=init_cmap(curr_disp.Cmap);

set(src, 'Pointer', 'hand');
ax=ancestor(hplot,'axes');
set(hplot,'linewidth',2);
cp=ax.CurrentPoint;
objt=findobj(ax,'Tag','tooltipl');
xlim=get(ax,'XLim');
dx=diff(xlim)/1e2;


if isempty(objt)
    text(ax,cp(1,1)+dx,cp(1,2),sprintf('%s',sprintf('%s',line_obj.print())),'Tag','tooltipl','EdgeColor',col_txt,'BackgroundColor',col_ax,'VerticalAlignment','Bottom','Interpreter','none','Color',col_txt);
else
    set(objt,'Position',[cp(1,1)+dx,cp(1,2)],'String',sprintf('%s',line_obj.print()),'EdgeColor',col_txt,'BackgroundColor',col_ax,'Color',col_txt);
end

end
