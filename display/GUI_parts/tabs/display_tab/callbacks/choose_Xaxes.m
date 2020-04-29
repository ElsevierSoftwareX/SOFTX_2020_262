function  choose_Xaxes(obj,~,main_figure)

layer=get_current_layer();
if isempty(layer)
    return;
end
curr_disp=get_esp3_prop('curr_disp');

idx=get(obj,'value');
str=get(obj,'String');

curr_disp.Xaxes_current=str{idx};
update_grid(main_figure);
update_grid_mini_ax(main_figure);
update_display_tab(main_figure);

end