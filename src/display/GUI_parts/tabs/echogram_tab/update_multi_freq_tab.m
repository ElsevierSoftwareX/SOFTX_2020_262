function update_multi_freq_tab(main_figure)

multi_freq_tab=getappdata(main_figure,'multi_freq_tab');
layer=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');

[idx_freq,~]=find_freq_idx(layer,curr_disp.Freq);


set(multi_freq_tab.primary_freq,'String',num2str(layer.Frequencies'/1e3,'%.0f kHz'),'value',idx_freq);
set(multi_freq_tab.secondary_freqs,'String',num2str(layer.Frequencies'/1e3,'%.0f kHz'),'value',1);


setappdata(main_figure,'multi_freq_tab',multi_freq_tab);