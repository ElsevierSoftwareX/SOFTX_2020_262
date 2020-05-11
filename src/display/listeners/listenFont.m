function listenFont(~,~,main_figure)
curr_disp=get_esp3_prop('curr_disp');
hfigs=getappdata(main_figure,'ExternalFigures');
hfigs(~isvalid(hfigs))=[];
format_color_gui(union(hfigs,main_figure),curr_disp.Font,curr_disp.Cmap);
%format_color_gui(main_figure,curr_disp.Font);
end
