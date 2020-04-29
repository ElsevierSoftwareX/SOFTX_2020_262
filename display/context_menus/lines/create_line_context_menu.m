function create_line_context_menu(line_plot,main_figure)
layer=get_current_layer();
%curr_disp=get_esp3_prop('curr_disp');

line_idx=layer.get_lines_per_ID(line_plot.UserData);

if isempty(line_idx)
    return;
end

line_obj=layer.Lines(line_idx);

context_menu=uicontextmenu(main_figure,'Tag','LineContextMenu','UserData',line_obj.ID);

uimenu(context_menu,'Label','Create Line referenced region','Callback',{@create_line_ref_region_cback,line_plot,main_figure});

end

function create_line_ref_region_cback(src,evtdata,line_plot,main_figure)
layer=get_current_layer();

line_idx=layer.get_lines_per_ID(line_plot.UserData);

if isempty(line_idx)
    return;
end

line_obj=layer.Lines(line_idx);

end