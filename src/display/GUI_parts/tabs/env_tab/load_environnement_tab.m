function load_environnement_tab(main_figure,option_tab_panel)

if isappdata(main_figure,'Env_tab')
    env_tab_comp=getappdata(main_figure,'Env_tab');
    delete(get(env_tab_comp.env_tab,'children'));
else
    env_tab_comp.env_tab=uitab(option_tab_panel,'Title','Environnement','tag','env');
end

%curr_disp=get_esp3_prop('curr_disp');

gui_fmt=init_gui_fmt_struct();
envdata=env_data_cl();

curr_sal=envdata.Salinity;
curr_temp=envdata.Temperature;
curr_ss=envdata.SoundSpeed;
curr_abs=10/1e3;

%%%%%%Environnement%%%%%%
pos=create_pos_3(7,2,gui_fmt.x_sep,gui_fmt.y_sep,gui_fmt.txt_w,gui_fmt.box_w,gui_fmt.box_h);

env_tab_comp.env_group=uipanel(env_tab_comp.env_tab,'Position',[0 0.0 0.4 1],'units','norm');

uicontrol(env_tab_comp.env_group,gui_fmt.txtStyle,'string','Model:','position',pos{1,1}{1});

env_tab_comp.att_model=uicontrol(env_tab_comp.env_group,gui_fmt.popumenuStyle,'string',{'Doonan et al (2003)' 'Francois & Garrison (1982)'},...
    'position',pos{1,1}{1}+[0 0 gui_fmt.box_w 0],'callback',{@update_envcal_values,main_figure});

uicontrol(env_tab_comp.env_group,gui_fmt.txtStyle,'String','Depth(m)','Position',pos{2,1}{1});
env_tab_comp.depth=uicontrol(env_tab_comp.env_group,gui_fmt.edtStyle,'position',pos{2,1}{2},'string',num2str(5,'%.1f'),'callback',{@update_envcal_values,main_figure});

uicontrol(env_tab_comp.env_group,gui_fmt.txtStyle,'String','SS(m/s)','Position',pos{5,1}{1});
env_tab_comp.soundspeed=uicontrol(env_tab_comp.env_group,gui_fmt.edtStyle,'position',pos{5,1}{2},'string',num2str(curr_ss,'%2f'),'callback',{@update_envcal_values,main_figure});
env_tab_comp.soundspeed_over=uicontrol(env_tab_comp.env_group,gui_fmt.chckboxStyle,'position',pos{5,1}{2}+[gui_fmt.box_w+gui_fmt.x_sep 0 0 0],'tooltipstring','Override soundspeed computation','callback',{@update_envcal_values,main_figure});

uicontrol(env_tab_comp.env_group,gui_fmt.txtStyle,'String','Att.(dB/km)','Position',pos{6,1}{1});
env_tab_comp.att=uicontrol(env_tab_comp.env_group,gui_fmt.edtStyle,'position',pos{6,1}{2},'string',num2str(curr_abs*1e3,'%.2f'),'callback',{@update_envcal_values,main_figure});
env_tab_comp.att_over=uicontrol(env_tab_comp.env_group,gui_fmt.chckboxStyle,'position',pos{6,1}{2}+[gui_fmt.box_w+gui_fmt.x_sep 0 0 0],'tooltipstring','Override absorption computation','callback',{@update_envcal_values,main_figure});

uicontrol(env_tab_comp.env_group,gui_fmt.txtStyle,'String',sprintf('Temp.(%cC)',char(hex2dec('00BA'))),'Position',pos{3,1}{1});
env_tab_comp.temp=uicontrol(env_tab_comp.env_group,gui_fmt.edtStyle,'position',pos{3,1}{2},'string',num2str(curr_temp,'%.2f'),'callback',{@update_envcal_values,main_figure});

uicontrol(env_tab_comp.env_group,gui_fmt.txtStyle,'String','Salinity.(PSU)','Position',pos{4,1}{1});
env_tab_comp.sal=uicontrol(env_tab_comp.env_group,gui_fmt.edtStyle,'position',pos{4,1}{2},'string',num2str(curr_sal,'%.2f'),'callback',{@update_envcal_values,main_figure});

env_tab_comp.string_cal=uicontrol(env_tab_comp.env_group,gui_fmt.txtStyle,'position',pos{1,2}{1}+[0 -3*(gui_fmt.txt_h) gui_fmt.box_w*3 3*(gui_fmt.txt_h)],...
    'string','','HorizontalAlignment','left');

p_button=pos{7,1}{1};
p_button(3)=gui_fmt.txt_w+gui_fmt.x_sep+gui_fmt.box_w;
uicontrol(env_tab_comp.env_group,gui_fmt.pushbtnStyle,'String','Apply','callback',{@apply_envdata_callback,main_figure},'position',p_button,'tooltipstring','Apply Environnemental values');

p_button=pos{7,2}{1}+[gui_fmt.box_w+gui_fmt.x_sep 0 0 0];
p_button(3)=gui_fmt.button_w;
uicontrol(env_tab_comp.env_group,gui_fmt.pushbtnStyle,'String','Save','callback',{@save_envdata_profiles_callback,main_figure},'position',p_button,'tooltipstring','Save Profiles');
uicontrol(env_tab_comp.env_group,gui_fmt.pushbtnStyle,'String','Reload','callback',{@reload_envdata_profiles_callback,main_figure},'position',p_button+[gui_fmt.button_w 0 0 0],'tooltipstring','Reload Profiles');

env_tab_comp.att_choice=uicontrol(env_tab_comp.env_group,gui_fmt.popumenuStyle,'string',{'Constant' 'Profile' 'Theoritical'},...
    'position',pos{6,2}{1}+[gui_fmt.box_w+gui_fmt.x_sep 0 0 0]);
env_tab_comp.ss_choice=uicontrol(env_tab_comp.env_group,gui_fmt.popumenuStyle,'string',{'Constant' 'Profile' 'Theoritical'},...
    'position',pos{5,2}{1}+[gui_fmt.box_w+gui_fmt.x_sep 0 0 0]);


env_tab_comp.ax_group=uipanel(env_tab_comp.env_tab,'Position',[0.4 0 0.6 1],'units','norm');

field={'temperature','salinity','soundspeed','absorption'};
label={'Temp(deg.)','Sal.(PSU)','SS(m/s)','Abs,(dB/km)'};
x_sep=0.05  ;
ll=(0.9-(numel(field))*x_sep)/numel(field);
for iax=1:numel(field)
    env_tab_comp.(['ax_' field{iax}])=axes(env_tab_comp.ax_group,...
        'Interactions',[],...
        'Toolbar',[],...
        'Units','Normalized',...
        'nextplot','add',...
        'Position',[0.1+(iax-1)*(ll+x_sep) 0.05 ll 0.75],...
        'XGrid','on','YGrid','on','box','on','tag',field{iax},...
        'YDir','reverse','XAxisLocation','top');
    if iax>1
        set(env_tab_comp.(['ax_' field{iax}]),'YTickLabel',{});
    end
    xlabel(env_tab_comp.(['ax_' field{iax}]),label{iax})
    rm_axes_interactions(env_tab_comp.(['ax_' field{iax}]));
end

ylabel(env_tab_comp.ax_temperature,'Depth(m)');



setappdata(main_figure,'Env_tab',env_tab_comp);

end

function save_envdata_profiles_callback(~,~,main_figure)
layer=get_current_layer();

layer.save_svp('');
layer.save_ctd('');

end

function reload_envdata_profiles_callback(~,~,main_figure)
layer=get_current_layer();

layer.load_svp('',layer.EnvData.SVP.ori);
layer.load_ctd('',layer.EnvData.CTD.ori);
update_environnement_tab(main_figure,0);

end

function update_envcal_values(~,~,main_figure)
curr_disp=get_esp3_prop('curr_disp');
layer=get_current_layer();

if ~isempty(layer)
    [trans_obj,~]=layer.get_trans(curr_disp);
    envdata=layer.EnvData;
else
    envdata=env_data_cl();
    trans_obj=[];
end

env_tab_comp=getappdata(main_figure,'Env_tab');

new_sal=str2double(get(env_tab_comp.sal,'string'));
if isnan(new_sal)||new_sal<0||new_sal>60
    new_sal=envdata.Salinity;
end

set(env_tab_comp.sal,'string',num2str(new_sal,'%.2f'));

new_temp=str2double(get(env_tab_comp.temp,'string'));
if isnan(new_temp)||new_temp<-5||new_temp>90
    new_temp=envdata.Temperature;
end
set(env_tab_comp.temp,'string',num2str(new_temp,'%.2f'));

new_d=str2double(get(env_tab_comp.depth,'string'));
if isnan(new_d)||new_d<0
    new_d=envdata.Depth;
end
set(env_tab_comp.depth,'string',num2str(new_d,'%.1f'));

if get(env_tab_comp.soundspeed_over,'value')==0
    c = seawater_svel_un95(new_sal,new_temp,new_d);
else
    c = str2double(get(env_tab_comp.soundspeed,'string'));
    if~(~isnan(c)&&c>=1000&&c<=2000)
        c=envdata.SoundSpeed;
    end
end
set(env_tab_comp.soundspeed,'string',num2str(c,'%.2f'));

if get(env_tab_comp.att_over,'value')==0||isempty(trans_obj)
    att_list=get(env_tab_comp.att_model,'String');
    att_model=att_list{get(env_tab_comp.att_model,'value')};
    f_c=nanmean(trans_obj.get_center_frequency());
    if f_c>120000&&strcmp(att_model,'Doonan et al (2003)')
        att_model='Francois & Garrison (1982)';
        set(env_tab_comp.att_model,'value',1);
    end
    
    switch att_model
        case 'Doonan et al (2003)'
            alpha = seawater_absorption(f_c/1e3, new_sal, new_temp, new_d,'doonan');
        case 'Francois & Garrison (1982)'
            alpha = seawater_absorption(f_c/1e3, new_sal, new_temp, new_d,'fandg');
    end
else
    alpha=str2double(get(env_tab_comp.att,'string'));
    if isnan(alpha)||alpha<0||alpha>200
        alpha=trans_obj.get_absorption()*1e3;
    end
    
end
layer.EnvData.Salinity=new_sal;
layer.EnvData.Depth=new_d;
layer.EnvData.Temperature=new_temp;

set(env_tab_comp.att,'string',num2str(nanmean(alpha),'%.2f'));

update_environnement_tab(main_figure,0);
end



