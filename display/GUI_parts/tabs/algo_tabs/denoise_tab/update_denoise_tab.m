
function update_denoise_tab(main_figure)

layer=get_current_layer();

denoise_tab_comp=getappdata(main_figure,'Denoise_tab');
if isempty(layer)
    return;
end

bandstops=layer.NotchFilter;
set(denoise_tab_comp.table_notch_filter,'Data',bandstops/1e3);
flim=layer.get_flim();

f_vec=flim(1):1e2:flim(end);
[h,w]=get_notch_filter(bandstops,f_vec);

set(denoise_tab_comp.applied_plot,'XData',w/1e3,'YData',h);
set(denoise_tab_comp.new_plot,'XData',w/1e3,'YData',h);
if numel(unique(flim))>1
    set(denoise_tab_comp.axe_filt,'XLim',flim/1e3);
else
     set(denoise_tab_comp.axe_filt,'XLim',flim(1)/1e3+[-10 10]);
end
setappdata(main_figure,'Denoise_tab',denoise_tab_comp);
end

