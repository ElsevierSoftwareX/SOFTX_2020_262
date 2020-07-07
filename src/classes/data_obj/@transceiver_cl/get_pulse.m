function [sim_pulse,y_tx_matched,t_pulse]=get_pulse(trans_obj)

f_s=1/trans_obj.get_params_value('SampleInterval',1);
FreqStart=(trans_obj.Params.FrequencyStart(1));
FreqEnd=(trans_obj.Params.FrequencyEnd(1));
T=trans_obj.get_params_value('PulseLength',1);
f_c = (FreqStart+FreqEnd)/2;


switch trans_obj.Config.TransceiverType
    case list_GPTs()
        Np = 4;
        t_pulse=(1:Np)/f_s; 
        env_pulse=ones(1,Np);
        sim_pulse = env_pulse.*exp(1i*2*pi*f_c*t_pulse);
        y_tx_matched=flipud(conj(sim_pulse));
       
    case list_WBTs()
        [sim_pulse,y_tx_matched,t_pulse]=trans_obj.generate_WBT_pulse();        
    otherwise
        t_pulse = 1/f_s:1/f_s:T;
        env_pulse=ones(size(t_pulse));

        if FreqStart == FreqEnd
            sim_pulse = env_pulse.*exp(1i*2*pi*f_c*t_pulse);
        else
            f_sweep=chirp(t_pulse,FreqStart,t_pulse(end),FreqEnd,'linear');
            sim_pulse=env_pulse.*f_sweep;
        end

        y_tx_matched=flipud(conj(sim_pulse));
end

end