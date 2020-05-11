function update_boat_position(main_figure,idx_ping,force)
try
    
    
    if ~isappdata(main_figure,'Map_tab')
        return;
    end
    
    
    layer=get_current_layer();
    
    if isempty(layer)||~isvalid(layer)
        return;
    end
    
    if ~isvalid(layer)
        return;
    end
    
    echo_tab_panel=getappdata(main_figure,'echo_tab_panel');
    
    if ~strcmpi(echo_tab_panel.SelectedTab.Tag,'axes_panel')
        return
    end
    
    axes_panel_comp=getappdata(main_figure,'Axes_panel');
    if isempty(axes_panel_comp)
        return;
    end
    
    curr_disp=get_esp3_prop('curr_disp');
    
    [trans_obj,~]=layer.get_trans(curr_disp);
    if isempty(trans_obj)
        return;
    end

    Lat=trans_obj.GPSDataPing.Lat;
    Long=trans_obj.GPSDataPing.Long;
    time_t=trans_obj.get_transceiver_time();
    nb_pings=length(time_t);
    idx_ping=nanmin(nb_pings,idx_ping);
    idx_ping=nanmax(1,idx_ping);
    
    
    
    map_tab_comp=getappdata(main_figure,'Map_tab');
    
    if map_tab_comp.update_boat_pos.Value==0&&~force
        return;
    end
        
    if isvalid(map_tab_comp.ax)
        if ~isvalid(map_tab_comp.boat_pos)
            map_tab_comp.boat_pos=matlab.graphics.chart.primitive.Line('Parent',map_tab_comp.ax,'marker','s','markersize',10,'markeredgecolor','r','markerfacecolor','k','tag','boat_pos');
            map_tab_comp.boat_pos.LatitudeDataMode='manual';
        end
        
        set(map_tab_comp.boat_pos,'LatitudeData',Lat(idx_ping),'LongitudeData',Long(idx_ping));
        u = findobj(map_tab_comp.ax,'Tag','name');
        delete(u);
        
    end
    
    hfigs=getappdata(main_figure,'ExternalFigures');
    if ~isempty(hfigs)
        hfigs(~isvalid(hfigs))=[];
    end
    
    if ~isempty(hfigs)
        idx_fig=find(strcmp({hfigs(:).Tag},'nav'));
        for iu=idx_fig
            if isvalid(hfigs(iu))
                hAllAxes = findobj(hfigs(iu),'type','axes');
                if ~isempty(Long)
                    for iui=1:length(hAllAxes)
                        boat_pos_obj=findobj(hAllAxes(iui),'tag','boat_pos');
                        if ~isvalid(boat_pos_obj)
                            boat_pos_obj=matlab.graphics.chart.primitive.Line('Parent',hAllAxes(iui),'marker','s','markersize',10,'markeredgecolor','r','markerfacecolor','k','tag','boat_pos');
                            boat_pos_obj.LatitudeDataMode='manual';
                        end
                        set(boat_pos_obj,'LatitudeData',Lat(idx_ping),'LongitudeData',Long(idx_ping));
                    end
                end
            end
        end
        
        
    end
    
catch err
    disp_perso(main_figure,'Error updating ship''s position.');
    print_errors_and_warnings([],'error',err);
end