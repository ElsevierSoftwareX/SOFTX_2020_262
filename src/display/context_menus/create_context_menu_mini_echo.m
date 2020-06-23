function create_context_menu_mini_echo(main_figure)
mini_axes_comp=getappdata(main_figure,'Mini_axes');
 
parent=ancestor(mini_axes_comp.echo_obj.main_ax,'figure');
delete(findobj(parent,'Tag','miniechoCtxtMenu'));
context_menu=uicontextmenu(parent,'Tag','miniechoCtxtMenu');
mini_axes_comp.echo_obj.echo_bt_surf.UIContextMenu=context_menu;
mini_axes_comp.echo_obj.main_ax.UIContextMenu=context_menu;
mini_axes_comp.patch_obj.UIContextMenu=context_menu;

if parent==main_figure
    uimenu(context_menu,'Label','Undock Overview','Callback',{@undock_mini_axes_callback,main_figure,'out_figure'});
else
    uimenu(context_menu,'Label','Dock Overview','Callback',{@undock_mini_axes_callback,main_figure,'main_figure'});
end

end