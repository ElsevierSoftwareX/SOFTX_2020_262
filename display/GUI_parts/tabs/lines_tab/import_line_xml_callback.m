function import_line_xml_callback(~,~,main_figure)
layer=get_current_layer();

layer.add_lines_from_line_xml();

display_lines(main_figure);
update_lines_tab(main_figure);
end