function [height_char,col_w]=get_top_panel_height(nb)
gui_fmt=init_gui_fmt_struct();
tmp= uicontrol('Style','text','units','pixels','String','ABCDEFGHIJKLMNOPQRSTUVWXYZ ','visible','off','FontSize',gui_fmt.txtStyle.fontsize);
h=get(tmp,'Extent');
height_char=(gui_fmt.y_sep*(nb+3)+gui_fmt.txt_h *nb)*h(4);
col_w = (gui_fmt.x_sep*2+gui_fmt.txt_w+gui_fmt.box_w)*h(3)/27;

delete(tmp);

end