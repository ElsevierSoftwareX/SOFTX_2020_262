function create_fish_density_echogramm_cback(~,~,main_figure)

layer=get_current_layer();
if isempty(layer)
    return;
end
curr_disp=get_esp3_prop('curr_disp');
[trans_obj,~]=layer.get_trans(curr_disp);

display_tab_comp=getappdata(main_figure,'Display_tab');

sv=trans_obj.Data.get_datamat('sv');

TS=str2double(get(display_tab_comp.TS,'string'));

data_mat=sv_to_density(sv,TS);

trans_obj.Data.replace_sub_data_v2('fishdensity',data_mat,[],[]);

curr_disp.setField('fishdensity');


end