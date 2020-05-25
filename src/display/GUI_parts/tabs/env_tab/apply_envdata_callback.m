
function apply_envdata_callback(~,~,main_figure)
curr_disp=get_esp3_prop('curr_disp');
layer=get_current_layer();

if ~isempty(layer)
    [~,idx_chan]=layer.get_trans(curr_disp);
    env_tab_comp=getappdata(main_figure,'Env_tab');
    
    new_d=str2double(get(env_tab_comp.depth,'string'));
    
    layer.EnvData.Depth=new_d;
    
    new_sal=str2double(get(env_tab_comp.sal,'string'));
    
    layer.EnvData.Salinity=new_sal;
    
    new_temp=str2double(get(env_tab_comp.temp,'string'));
    
    layer.EnvData.Temperature=new_temp;
    
    new_ss =str2double(get(env_tab_comp.soundspeed,'string'));
    new_abs=str2double(get(env_tab_comp.att,'string'));
    
    att_list=get(env_tab_comp.att_choice,'String');
    att_env=att_list{get(env_tab_comp.att_choice,'value')};

    layer.EnvData.set_ctd(layer.EnvData.CTD.depth,layer.EnvData.CTD.temperature,layer.EnvData.CTD.salinity,lower(att_env));
      
    ss_list=get(env_tab_comp.ss_choice,'String');
    ss_env=ss_list{get(env_tab_comp.ss_choice,'value')};

    layer.EnvData.set_svp(layer.EnvData.SVP.depth,layer.EnvData.SVP.soundspeed,lower(ss_env));
    
    layer.layer_computeSpSv('new_soundspeed',new_ss,'absorption',new_abs/1e3,'absorption_f',layer.Frequencies(idx_chan));
    
    cids_up=union({'main','mini'},curr_disp.SecChannelIDs,'stable');
    update_axis(main_figure,0,'main_or_mini',cids_up,'force_update',1);
    display_bottom(main_figure,cids_up);
    clear_regions(main_figure,{},cids_up);
    display_regions(main_figure,cids_up);
    set_alpha_map(main_figure,'main_or_mini',cids_up,'update_bt',0);
        
    
end

update_environnement_tab(main_figure,1);

end
