function set_pulse_Teff(trans_obj)

if ~isempty(trans_obj.Filters)
    if trans_obj.Filters(1).DecimationFactor>0
        [sim_pulse,y_tx_matched,t_pulse]=trans_obj.get_pulse();
        Np=round(nansum(abs(y_tx_matched).^2)/(nanmax(abs(y_tx_matched).^2)));         
        tmp=Np*trans_obj.get_params_value('SampleInterval',[]);
    else
        [tmp,~]=trans_obj.get_pulse_length();        
    end    
else
    [tmp,~]=trans_obj.get_pulse_length();    
end

trans_obj.Params.TeffPulseLength=tmp(trans_obj.Params.PingNumber);

end