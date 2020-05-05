function create_context_menu_int_plot(int_plot)
reg_plot_cxtmenu = uicontextmenu(ancestor(int_plot,'figure'));
uimenu(reg_plot_cxtmenu,'Label','Display_grid','Checked','on','Callback',{@display_grid_cbak,int_plot});
uimenu(reg_plot_cxtmenu,'Label','Copy to clipboard','Callback',{@copy_cb_cbak,int_plot});
int_plot.UIContextMenu=reg_plot_cxtmenu;
end


function display_grid_cbak(src,evt,int_plot)
grid(int_plot.Parent);
switch src.Checked
    case 'off'
        src.Checked='on';
    case 'on'
        src.Checked='off';
end

end

function copy_cb_cbak(src,evt,int_plot)

print(ancestor(int_plot,'figure'),'-clipboard','-dbitmap');

end

