function update_environnement_tab(main_figure,new)

curr_disp=get_esp3_prop('curr_disp');
layer=get_current_layer();

if ~isempty(layer)
    [trans_obj,~]=layer.get_trans(curr_disp);
    envdata=layer.EnvData;
else
    envdata=env_data_cl();
    trans_obj=[];
    return;
end

env_tab_comp=getappdata(main_figure,'Env_tab');
att_list=get(env_tab_comp.att_model,'String');
att_model=att_list{get(env_tab_comp.att_model,'value')};

f_c=nanmean(trans_obj.get_center_frequency());

if new>0
    set(env_tab_comp.sal,'string',num2str(envdata.Salinity,'%.2f'));
    
    set(env_tab_comp.temp,'string',num2str(envdata.Temperature,'%.2f'));
    
    set(env_tab_comp.depth,'string',num2str(envdata.Depth,'%.1f'));
    
    def_alpha = seawater_absorption(f_c/1e3, envdata.Salinity, envdata.Temperature, envdata.Depth,att_model)/1e3;
    def_ss=seawater_svel_un95(envdata.Salinity,envdata.Temperature,envdata.Depth);
   
    set(env_tab_comp.soundspeed,'string',num2str(def_ss,'%.2f'));
    
    set(env_tab_comp.att,'string',num2str(def_alpha*1e3,'%.2f'));
    
    att_idx=find(strcmpi(get(env_tab_comp.att_choice,'String'), envdata.CTD.ori));
    env_tab_comp.att_choice.Value=att_idx;
    
    ss_idx=find(strcmpi(get(env_tab_comp.ss_choice,'String'),envdata.SVP.ori));
    env_tab_comp.ss_choice.Value=ss_idx;
end


field={'temperature','salinity','soundspeed','absorption'};

d_trans=trans_obj.get_transceiver_depth([],1);
for iax=1:numel(field)
    %delete(findobj(env_tab_comp.(['ax_' field{iax}]),'Type','line'));
    cla(env_tab_comp.(['ax_' field{iax}]));
    ylim(env_tab_comp.(['ax_' field{iax}]),[nanmin(d_trans) nanmax(d_trans)]);
    yline(env_tab_comp.(['ax_' field{iax}]),str2double(env_tab_comp.depth.String),'--','Color','k');
    yline(env_tab_comp.(['ax_' field{iax}]),envdata.Depth,'--','Color',[0 0.6 0]);
end

xline(env_tab_comp.ax_temperature,str2double(env_tab_comp.temp.String),'--','Color','k');
xline(env_tab_comp.ax_salinity,str2double(env_tab_comp.sal.String),'--','Color','k');
xline(env_tab_comp.ax_soundspeed,str2double(env_tab_comp.soundspeed.String),'--','Color','k');
xline(env_tab_comp.ax_absorption,str2double(env_tab_comp.att.String),'--','Color','k');

def_alpha = seawater_absorption(f_c/1e3, str2double(env_tab_comp.sal.String), str2double(env_tab_comp.temp.String), d_trans,att_model)/1e3;
def_ss=seawater_svel_un95(str2double(env_tab_comp.sal.String),str2double(env_tab_comp.temp.String),d_trans);

plot(env_tab_comp.ax_absorption,def_alpha*1e3,d_trans,'-','color',[0 0 0.6]);
plot(env_tab_comp.ax_soundspeed,def_ss,d_trans,'-','color',[0 0 0.6]);

if ~isempty(envdata.CTD.depth)
     alpha_pro=trans_obj.compute_absorption(envdata,'profile');
     plot(env_tab_comp.ax_absorption,alpha_pro*1e3,d_trans,'Color',[0.6 0 0]);
    plot(env_tab_comp.ax_salinity,envdata.CTD.salinity,envdata.CTD.depth,'Color',[0.6 0 0]);
    plot(env_tab_comp.ax_temperature,envdata.CTD.temperature,envdata.CTD.depth,'Color',[0.6 0 0]);
end
xline(env_tab_comp.ax_temperature,envdata.Temperature,'--','Color',[0 0.6 0]);
xline(env_tab_comp.ax_salinity,envdata.Salinity,'--','Color',[0 0.6 0]);
xline(env_tab_comp.ax_absorption,nanmean(trans_obj.get_absorption())*1e3,'--','Color',[0 0.6 0]);


if ~isempty(envdata.SVP.depth)
     [c_pro,~]=trans_obj.compute_soundspeed_and_range(envdata,'profile');
     plot(env_tab_comp.ax_soundspeed,c_pro,d_trans,'--','Color',[0.6 0 0]);
    plot(env_tab_comp.ax_soundspeed,envdata.SVP.soundspeed,envdata.SVP.depth,'Color',[0.6 0 0]);
end
xline(env_tab_comp.ax_soundspeed,envdata.SoundSpeed,'--','Color',[0 0.6 0]);


str_disp=layer.get_env_str(curr_disp);

set(env_tab_comp.string_cal,'string',str_disp);

end
