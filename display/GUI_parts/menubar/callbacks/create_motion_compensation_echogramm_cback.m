function create_motion_compensation_echogramm_cback(~,~,main_figure)

layer=get_current_layer();
if isempty(layer)
    return;
end
curr_disp=get_esp3_prop('curr_disp');
[~,idx_freq]=layer.get_trans(curr_disp);
layer.create_motion_comp_subdata(idx_freq,1);

curr_disp.setField('motioncompensation');


end