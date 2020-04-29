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
if isnan(new_d)
    new_d=5;
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
    
    if curr_disp.Freq>120000&&strcmp(att_model,'Doonan et al (2003)')
        att_model='Francois & Garrison (1982)';
        set(env_tab_comp.att_model,'value',1);
    end
    
    switch att_model
        case 'Doonan et al (2003)'
            alpha = seawater_absorption(curr_disp.Freq/1e3, new_sal, new_temp, new_d,'doonan');
        case 'Francois & Garrison (1982)'
            alpha = seawater_absorption(curr_disp.Freq/1e3, new_sal, new_temp, new_d,'fandg');
    end
else
    alpha=str2double(get(env_tab_comp.att,'string'));
    if isnan(alpha)||alpha<0||alpha>200
        alpha=trans_obj.get_absorption()*1e3;
    end
 
end
set(env_tab_comp.att,'string',num2str(nanmean(alpha),'%.2f'));

str_disp=layer.get_env_str(curr_disp);

set(env_tab_comp.string_cal,'string',str_disp);

end