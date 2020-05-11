function str_disp=get_env_str(layer_obj,curr_disp)

trans_obj=layer_obj.get_trans(curr_disp);

new_ss=layer_obj.EnvData.SoundSpeed;

[new_abs,abs_ori]=trans_obj.get_absorption();

switch layer_obj.EnvData.SVP.ori
    case 'constant'        
        ss_str=sprintf('Const. Soundspeed: %.2f m/s',new_ss);
    case 'theoritical'
        ss_str='Soundspeed from theoritical SVP';
    otherwise
        ss_str='Soundspeed from SVP profile';
end

switch abs_ori
    case 'constant'        
        abs_str=sprintf('Const. Abs.: %.2f dB/km',new_abs(1)*1e3);
    case 'theoritical'
        abs_str='Absorption from theoritical profile';
    otherwise
        abs_str='Absorption from CTD profile';
end


str_disp=sprintf('Currently used values:\n%s\n%s\n',...
    ss_str,abs_str);
