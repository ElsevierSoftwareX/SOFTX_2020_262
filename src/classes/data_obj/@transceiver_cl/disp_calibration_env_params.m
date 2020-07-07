function disp_calibration_env_params(trans_obj,env_data_obj)


[alpha,ori_abs] = trans_obj.get_absorption();
cal=trans_obj.get_cal();

fprintf('    Channel %s:\n',trans_obj.Config.ChannelID);
fprintf('        Calibration values : G0=%.2f dB SaCorr=%.2f dB EQA %.2f\n',cal.G0,cal.SACORRECT,cal.EQA);
if ~isempty(env_data_obj)
    switch env_data_obj.SVP.ori
        case 'constant'
            ss_str=sprintf('Const. Soundspeed: %.2f m/s',env_data_obj.SoundSpeed);
        case 'theoritical'
            ss_str='Soundspeed from theoritical SVP';
        otherwise
            ss_str='Soundspeed from SVP profile';
    end
    
    switch ori_abs
        case 'constant'
            abs_str=sprintf('Const. Abs.: %.2f dB/km',alpha(1)*1e3);
        case 'theoritical'
            abs_str='Absorption from theoritical profile';
        otherwise
            abs_str='Absorption from CTD profile';
    end
    fprintf('        %s\n        %s\n',abs_str,ss_str); 
else
    fprintf('\n');
end



