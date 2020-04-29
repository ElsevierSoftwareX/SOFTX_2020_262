function cal_tot=extract_cal_to_apply(layer_obj,cal_node)

[cal_path,~,~]=fileparts(layer_obj.Filename{1});
cal_file=fullfile(cal_path,'cal_echo.csv');

cal_lay=init_cal_struct(layer_obj);
cal_f=init_cal_struct(cal_file);
cal_master=init_cal_struct(cal_node);

cal_tot=merge_calibration(cal_lay,cal_f);
cal_tot=merge_calibration(cal_tot,cal_master);
