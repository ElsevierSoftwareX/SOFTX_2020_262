function tab_menu=create_context_menu_tabs(main_figure,tab_h,tab_name)

tab_menu = uicontextmenu(ancestor(tab_h,'figure'));
uimenu(tab_menu,'Label','Undock to External Window','Callback',{@undock_tab_callback,main_figure,tab_name,'new_fig'});
switch tab_name
    case 'map'
        uimenu(tab_menu,'Label','Undock to Option panel','Callback',{@undock_tab_callback,main_figure,tab_name,'opt_tab'});
        uimenu(tab_menu,'Label','Undock to Echogram panel','Callback',{@undock_tab_callback,main_figure,tab_name,'echo_tab'});
        uimenu(tab_menu,'Label','Close','Callback',{@close_tab_callback,main_figure,tab_name});
    case 'echoint_tab'
    otherwise
        uimenu(tab_menu,'Label','Undock to Option panel','Callback',{@undock_tab_callback,main_figure,tab_name,'opt_tab'});
        uimenu(tab_menu,'Label','Undock to Echogram panel','Callback',{@undock_tab_callback,main_figure,tab_name,'echo_tab'});
end

end

function close_tab_callback(src,evt,main_figure,tab_name)

switch tab_name
    
    case 'map'
        map_tab_comp=getappdata(main_figure,'Map_tab');
        delete(map_tab_comp.map_tab);
        rmappdata(main_figure,'Map_tab');
        
end
end