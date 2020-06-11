

%% Function
function load_bad_pings_tab(main_figure,algo_tab_panel)

tab_main = uitab(algo_tab_panel,'Title','Bad Data');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Bad Pings Detection Algorithm%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
algo_name = 'BadPingsV2';
panel_comp=load_algo_panel('main_figure',main_figure,...
        'panel_h',uipanel(tab_main,'Position',[0 0 0.3 1]),...
        'algo_name',algo_name,...
        'title','Bad Pings Detection');

gui_fmt=init_gui_fmt_struct();
gui_fmt.txt_w=gui_fmt.txt_w*1.2;
pos=create_pos_3(7,2,gui_fmt.x_sep,gui_fmt.y_sep,gui_fmt.txt_w,gui_fmt.box_w,gui_fmt.box_h);

p_button=pos{6,1}{1};
p_button(3)=gui_fmt.button_w;

uicontrol(panel_comp.container,gui_fmt.pushbtnStyle,'String','Reset','pos',p_button+[3*gui_fmt.button_w 0 0 0],'callback',{@reset_bad_pings_cback,main_figure},'tag','curr');
uicontrol(panel_comp.container,gui_fmt.pushbtnStyle,'String','Reset all','pos',p_button+[4*gui_fmt.button_w 0 0 0],'callback',{@reset_bad_pings_cback,main_figure},'tag','all');
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Spike Detection%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
algo_name='SpikesRemoval';
panel_comp=load_algo_panel('main_figure',main_figure,...
        'panel_h',uipanel(tab_main,'Position',[0.6 0 0.4 1]),...
        'algo_name',algo_name,...
        'title','Spikes Detection');

p_button=pos{6,1}{1};
p_button(3)=gui_fmt.button_w;
uicontrol(panel_comp.container,gui_fmt.pushbtnStyle,'String','Reset','pos',p_button+[1*gui_fmt.button_w 0 0 0],'callback',{@rm_spikes_cback,main_figure});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Dropouts Detection%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
algo_name = 'DropOuts';
load_algo_panel('main_figure',main_figure,...
        'panel_h',uipanel(tab_main,'Position',[0.3 0 0.3 1]),...
        'algo_name',algo_name,...
        'title','Dropouts Detection',...
        'save_fcn_bool',true);

end

function rm_spikes_cback(src,~,main_figure)

curr_disp=get_esp3_prop('curr_disp');
layer = get_current_layer();

[trans_obj_tot,idx_t]=layer.get_trans(curr_disp);

trans_obj_tot.set_spikes([],[],0); 

set_alpha_map(main_figure,'update_cmap',0,'update_under_bot',0,'main_or_mini',union({'main','mini'},layer.ChannelID(idx_t),'stable'));


end

function reset_bad_pings_cback(src,~,main_figure)

curr_disp=get_esp3_prop('curr_disp');
layer = get_current_layer();

switch src.Tag
    case 'curr'
        [trans_obj_tot,idx_t]=layer.get_trans(curr_disp);
    case 'all'
        trans_obj_tot=layer.Transceivers;
        idx_t=1:numel(trans_obj_tot);
end

for it=1:numel(trans_obj_tot)
    trans_obj=trans_obj_tot(it);
    old_bot=trans_obj.Bottom;
    
    new_bot=old_bot;
    new_bot.Tag(:)=true;
    
    curr_disp.Bot_changed_flag=1;
    trans_obj.Bottom=new_bot;
    
    add_undo_bottom_action(main_figure,trans_obj,old_bot,new_bot);
end
set_alpha_map(main_figure,'update_cmap',0,'update_under_bot',0,'main_or_mini',union({'main','mini'},layer.ChannelID(idx_t),'stable'));
info_panel_comp=getappdata(main_figure,'Info_panel');
set(info_panel_comp.percent_BP,'string',trans_obj.bp_percent2str());

end
