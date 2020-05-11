function export_line_callback(~,~,main_figure)

layer=get_current_layer();

if isempty(layer)
    return;
end

write_line_to_line_xml(layer);
disp_perso(main_figure,'Lines Exported');

end
