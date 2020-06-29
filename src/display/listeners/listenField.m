function listenField(~,~,main_figure)
load_bar_comp=getappdata(main_figure,'Loading_bar');
load_bar_comp.progress_bar.setText('Changing displayed data...');

curr_disp=get_esp3_prop('curr_disp');
cids_up=union({'main','mini'},curr_disp.SecChannelIDs,'stable');
update_axis(main_figure,0,'main_or_mini',cids_up,'force_update',1);
order_stacks_fig(main_figure,curr_disp);
update_info_panel([],[],1);

%load_bar_comp.progress_bar.setText('');


end