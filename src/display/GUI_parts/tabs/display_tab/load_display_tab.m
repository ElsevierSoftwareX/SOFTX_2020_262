%% load_display_tab.m
%
% TODO: write short description of function
%
%% Help
%
% *USE*
%
% TODO: write longer description of function
%
% *INPUT VARIABLES*
%
% * |main_figure|: Handle to main ESP3 window
% * |option_tab_panel|: TODO: write description and info on variable
%
% *OUTPUT VARIABLES*
%
% NA
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2015-06-25: first version (Yoann Ladroit).
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function load_display_tab(main_figure,option_tab_panel)

curr_disp=get_esp3_prop('curr_disp');
display_tab_comp.display_tab=uitab(option_tab_panel,'Title','Display Option','tag','disp');
nb_col=8;

size_bttn_grp=[0 0.77 1 0.23];

gui_fmt=init_gui_fmt_struct();
gui_fmt.txt_w=gui_fmt.txt_w/2.5;
gui_fmt.box_w=gui_fmt.box_w*2;

pos=create_pos_3(2,nb_col,gui_fmt.x_sep,gui_fmt.y_sep,gui_fmt.txt_w,gui_fmt.box_w,gui_fmt.box_h);

display_tab_comp.top_button_group=uipanel(display_tab_comp.display_tab,'units','norm','Position',size_bttn_grp);

uicontrol(display_tab_comp.top_button_group,gui_fmt.txtStyle,'String','Chan.','Position',pos{1,1}{1});
display_tab_comp.tog_freq=uicontrol(display_tab_comp.top_button_group,gui_fmt.popumenuStyle,'String','--','Value',1,'Position',pos{1,1}{2},...
    'Callback',{@choose_freq,main_figure});

uicontrol(display_tab_comp.top_button_group,gui_fmt.txtStyle,'String','Data','Position',pos{2,1}{1});
display_tab_comp.tog_type=uicontrol(display_tab_comp.top_button_group,gui_fmt.popumenuStyle,'String','--','Value',1,'Position',pos{2,1}{2},...
    'Callback',{@choose_field,main_figure});

uicontrol(display_tab_comp.top_button_group,gui_fmt.txtStyle,'String','X grid:','Position',pos{1,2}{1});
display_tab_comp.grid_x=uicontrol(display_tab_comp.top_button_group,gui_fmt.edtStyle,'position',pos{1,2}{2}+[0 0 -gui_fmt.box_w/2 0],'string','');
display_tab_comp.tog_axes=uicontrol(display_tab_comp.top_button_group,gui_fmt.popumenuStyle,'String','--','Value',1,'Position',pos{1,2}{2}+[gui_fmt.box_w/2+gui_fmt.x_sep 0 0 0],...
    'Callback',{@choose_Xaxes,main_figure});

uicontrol(display_tab_comp.top_button_group,gui_fmt.txtStyle,'String','Y grid:','Position',pos{2,2}{1});
display_tab_comp.grid_y=uicontrol(display_tab_comp.top_button_group,gui_fmt.edtStyle,'position',pos{2,2}{2}+[0 0 -gui_fmt.box_w/2 0],'string','');
display_tab_comp.grid_y_unit=uicontrol(display_tab_comp.top_button_group,gui_fmt.txtStyle,'position',pos{2,2}{2}+[gui_fmt.box_w/2+gui_fmt.x_sep 0 0 0],'HorizontalAlignment','left','string','meters');

set([display_tab_comp.grid_x display_tab_comp.grid_y],'callback',{@change_grid_callback,main_figure})

cax=[0 1];

second_group_start = 4;
gui_fmt=init_gui_fmt_struct();
gui_fmt.txt_w=gui_fmt.txt_w/2;

pos=create_pos_3(2,nb_col,gui_fmt.x_sep,gui_fmt.y_sep,gui_fmt.txt_w,gui_fmt.box_w,gui_fmt.box_h);

uicontrol(display_tab_comp.top_button_group,gui_fmt.txtStyle,'String','TS(dB)','Position',pos{1,second_group_start}{1});
display_tab_comp.TS=uicontrol(display_tab_comp.top_button_group,gui_fmt.edtStyle,'position',pos{1,second_group_start}{2},...
    'string',-50,'callback',{@set_TS_cback,main_figure},'TooltipString','TS used for Fish density estimation display');

uicontrol(display_tab_comp.top_button_group,gui_fmt.txtStyle,'String','Trans.%','Position',pos{2,second_group_start}{1});
display_tab_comp.trans_bot=uicontrol(display_tab_comp.top_button_group,gui_fmt.edtStyle,'position',pos{2,second_group_start}{2},...
    'string',num2str(curr_disp.UnderBotTransparency,'%.0f'),'callback',{@set_bot_trans_cback,main_figure},'TooltipString','Under Bottom Data Transparency');

uicontrol(display_tab_comp.top_button_group,gui_fmt.txtStyle,'String','C-Max','Position',pos{1,second_group_start+1}{1});
uicontrol(display_tab_comp.top_button_group,gui_fmt.txtStyle,'String','C-Min','Position',pos{2,second_group_start+1}{1});
%uicontrol(display_tab_comp.top_button_group,gui_fmt.txtStyle,'String','Min','Position',[540 85 60 30],'Fontweight','bold');

display_tab_comp.caxis_up=uicontrol(display_tab_comp.top_button_group,gui_fmt.edtStyle,'position',pos{1,second_group_start+1}{2},'string',cax(2));
display_tab_comp.caxis_down=uicontrol(display_tab_comp.top_button_group,gui_fmt.edtStyle,'position',pos{2,second_group_start+1}{2},'string',cax(1));

uicontrol(display_tab_comp.top_button_group,gui_fmt.txtStyle,'String','X-mov','Position',pos{1,second_group_start+2}{1});
display_tab_comp.move_dx=uicontrol(display_tab_comp.top_button_group,gui_fmt.edtStyle,'position',pos{1,second_group_start+2}{2},...
    'string',num2str(curr_disp.Move_dy_dx(2)*100,'%.0f'),'callback',@set_move_dx_dy,'TooltipString','Percentage of echogramm being updated when moving with keyboard along X-axis','tag','dx');

uicontrol(display_tab_comp.top_button_group,gui_fmt.txtStyle,'String','Y-mov','Position',pos{2,second_group_start+2}{1});
display_tab_comp.move_dy=uicontrol(display_tab_comp.top_button_group,gui_fmt.edtStyle,'position',pos{2,second_group_start+2}{2},...
    'string',num2str(curr_disp.Move_dy_dx(1)*100,'%.0f'),'callback',@set_move_dx_dy,'TooltipString','Percentage of echogramm being updated when moving with keyboard along Y-axis','tag','dy');


uicontrol(display_tab_comp.top_button_group,gui_fmt.txtStyle,'String','X-load','Position',pos{1,second_group_start+3}{1});
display_tab_comp.disp_dx=uicontrol(display_tab_comp.top_button_group,gui_fmt.edtStyle,'position',pos{1,second_group_start+3}{2},...
    'string',num2str(curr_disp.Disp_dy_dx(2)*100,'%.0f'),'callback',{@set_disp_dx_dy,main_figure},'TooltipString','Percentage of echogramm being loaded outside display area (X-axis)','tag','dx');

uicontrol(display_tab_comp.top_button_group,gui_fmt.txtStyle,'String','Y-load','Position',pos{2,second_group_start+3}{1});
display_tab_comp.disp_dy=uicontrol(display_tab_comp.top_button_group,gui_fmt.edtStyle,'position',pos{2,second_group_start+3}{2},...
    'string',num2str(curr_disp.Disp_dy_dx(1)*100,'%.0f'),'callback',{@set_disp_dx_dy,main_figure},'TooltipString','Percentage of echogramm being loaded outside display area (Y-axis)','tag','dy');


set([display_tab_comp.caxis_up display_tab_comp.caxis_down],'callback',{@set_caxis,main_figure});

p_button=pos{1,second_group_start+4}{1};
p_button(3)=gui_fmt.button_w;

display_tab_comp.sec_freq_disp=uicontrol(display_tab_comp.top_button_group,gui_fmt.chckboxStyle,'Value',curr_disp.DispSecFreqs,...
    'String','Disp Other Channels','Position',pos{2,second_group_start+4}{1}+[0 0 gui_fmt.txt_w*2 0],...
    'BackgroundColor','w',...
    'callback',{@change_DispSecFreqs_cback,main_figure});

uicontrol(display_tab_comp.top_button_group,gui_fmt.pushbtnStyle,'String','Motion','pos',p_button,'callback',{@display_attitude_cback,main_figure});
uicontrol(display_tab_comp.top_button_group,gui_fmt.pushbtnStyle,'String','Speed','pos',p_button+[gui_fmt.button_w 0 0 0],'callback',{@display_speed_callback,main_figure});

%set(findobj(display_tab_comp.display_tab, '-property', 'Enable'), 'Enable', 'off');
setappdata(main_figure,'Display_tab',display_tab_comp);


end

function set_move_dx_dy(src,~)
curr_disp=get_esp3_prop('curr_disp');

val=str2double(get(src,'string'));

switch src.Tag
    case'dx'
        id=2;
    case 'dy'
        id=1;
end

if val>0&&val<=100
    curr_disp.Move_dy_dx(id)=val/100;
else
    val=curr_disp.Move_dy_dx(id)*100;
end

set(src,'string', num2str(val,'%.0f'));
end

function set_disp_dx_dy(src,~,main_figure)
curr_disp=get_esp3_prop('curr_disp');

val=str2double(get(src,'string'));

switch src.Tag
    case'dx'
        id=2;
    case 'dy'
        id=1;
end

if val>0&&val<=500
    curr_disp.Disp_dy_dx(id)=val/100;
else
    val=curr_disp.Disp_dy_dx(id)*100;
end

set(src,'string', num2str(val,'%.0f'));

axes_panel_comp=getappdata(main_figure,'Axes_panel');
main_axes=axes_panel_comp.echo_obj.main_ax;
set(main_axes,'YLim',main_axes.YLim);

end


function change_DispSecFreqs_cback(src,~,main_figure)
curr_disp=get_esp3_prop('curr_disp');
curr_disp.DispSecFreqs=get(src,'Value');
end

