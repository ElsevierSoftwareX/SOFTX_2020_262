function disp_perso(main_figure,disp_str)
if ~isempty(main_figure)
    load_bar_comp=getappdata(main_figure,'Loading_bar');
    if ~isempty(load_bar_comp)
        load_bar_comp.progress_bar.setText(disp_str);
    else
        disp(disp_str);
    end
else
    disp(disp_str);
end