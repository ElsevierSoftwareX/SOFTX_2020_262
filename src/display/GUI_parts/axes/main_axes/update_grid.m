function update_grid(main_figure)

layer=get_current_layer();
axes_panel_comp=getappdata(main_figure,'Axes_panel');
curr_disp=get_esp3_prop('curr_disp');

[trans_obj,~]=layer.get_trans(curr_disp);

if isempty(trans_obj)
    return;
end
% profile on;

echo_obj = axes_panel_comp.echo_obj;

try  
    curr_disp.init_grid_val(trans_obj);
       
    echo_obj.update_echo_grid(trans_obj,'curr_disp',curr_disp);
     
    secondary_freq=getappdata(main_figure,'Secondary_freq');
    
    if isempty(secondary_freq)
        return;
    end
    
    if isempty(secondary_freq.echo_obj)
        return;
    end
    
    if ismember(secondary_freq.echo_obj(1).echo_usrdata.geometry_y,{'depth' 'range'})
        ylim=get(secondary_freq.echo_obj(1).main_ax,'Ylim');
        set(secondary_freq.echo_obj.get_main_ax(),'ytick',floor((ylim(1):curr_disp.Grid_y:ylim(2))/curr_disp.Grid_y)*curr_disp.Grid_y);
        set(secondary_freq.echo_obj.get_vert_ax(),'ytick',floor((ylim(1):curr_disp.Grid_y:ylim(2))/curr_disp.Grid_y)*curr_disp.Grid_y);
    end
    
catch err
    warning('Error while updating grid..');
    print_errors_and_warnings(1,'error',err);
end
% profile off;
% profile viewer;
end