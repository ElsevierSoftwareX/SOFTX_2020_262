function bs_analysis_callback(~,~,main_figure)
update_algos(main_figure);
curr_disp=get_esp3_prop('curr_disp');
layer=get_current_layer();

if isempty(layer)
return;
end
    
[trans_obj,idx_freq]=layer.get_trans(curr_disp);

choice=question_dialog_fig(main_figure,'Ray Tracing?','Do you want to use ray-tracing?');
% Handle response
switch choice
    case 'Yes'
        ray_tray=1;   
    otherwise
        ray_tray=0;
end
% 
phi_std_thr=20/180*pi;
trans_angle=[10 -30 90];%pitch roll
pos_trans=[-5;-5;-5];%dalong dacross dz
att_cal=[0 0 0];
 trans_obj.set_position(pos_trans,trans_angle);
bs_analysis(layer,'IdxFreq',idx_freq,'RayTrayBool',ray_tray,'PhiStdThr',phi_std_thr,'AttCal',att_cal)

end