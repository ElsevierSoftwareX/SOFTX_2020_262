function listenCax(~,~,main_figure)
%profile on;
replace_interaction(main_figure,'interaction','KeyPressFcn','id',1);
update_display_tab(main_figure);
curr_disp=get_esp3_prop('curr_disp');
layer=get_current_layer();
set_alpha_map(main_figure,'main_or_mini',union({'main','mini'},layer.ChannelID),'update_bt',0);

track_tab_comp=getappdata(main_figure,'ST_Tracks');

cax=curr_disp.getCaxField('singletarget');

caxis(track_tab_comp.ax_pos,cax);

% link_ylim_to_echo_clim([],[],main_figure,'sv_f');
% link_ylim_to_echo_clim([],[],main_figure,'ts_f');
fix_ylim([],[],main_figure,'sv_f');
fix_ylim([],[],main_figure,'ts_f');
%drawnow;
update_echo_int_alphamap(main_figure);

replace_interaction(main_figure,'interaction','KeyPressFcn','id',1,'interaction_fcn',{@keyboard_func,main_figure});
% profile off;
% profile viewer;
load_bar_comp=getappdata(main_figure,'Loading_bar');
load_bar_comp.progress_bar.setText('');

end