function height_char=get_top_panel_height(nb)
gui_fmt=init_gui_fmt_struct();
tmp= uicontrol('Style','text','units','pixels','String','x');
h=get(tmp,'Extent');

height_char=(gui_fmt.y_sep*(nb+3)+gui_fmt.txt_h *nb)*h(4);

delete(tmp);

end