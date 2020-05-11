function save_new_display_algos_config_callback(~,~,main_figure,name)

[answer,cancel]=input_dlg_perso(main_figure,'Enter new settings name',{'New settings name'},...
    {'%s'},{''});
if cancel
    return;
end

new_name=answer{1};

algo_panels = getappdata(main_figure,'Algo_panels');
if isempty(algo_panels)
    return;
end

panel_obj=algo_panels.get_algo_panel(name);

if isempty(panel_obj) || isempty(panel_obj.default_params_h)
    return;
end

names=get(panel_obj.default_params_h,'String');
names=union(names,new_name);

idx=find(strcmpi(names,new_name));
set(panel_obj.default_params_h,'String',names,'value',idx);

save_display_algos_config_callback([],[],main_figure,name)

end