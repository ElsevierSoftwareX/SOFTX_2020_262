function [f_min_3dB,f_max_3dB]=get_3dB_f(trans_obj)

        [sim_pulse,y_tx_matched,t_pulse]=trans_obj.get_pulse();
        
        idx_3db=abs(y_tx_matched.^2)>=nanmax(abs(y_tx_matched.^2)/2);
        FreqStart=(trans_obj.get_params_value('FrequencyStart',1));
        FreqEnd=(trans_obj.get_params_value('FrequencyEnd',1));
        f_sweep=linspace(FreqStart,FreqEnd,numel(y_tx_matched));
        f_min_3dB=nanmin(f_sweep(idx_3db));
        f_max_3dB=nanmax(f_sweep(idx_3db));
        
        