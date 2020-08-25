function set_pulse_comp_Teff(trans_obj)

if ~isempty(trans_obj.Filters)
    if trans_obj.Filters(1).DecimationFactor>0
        [sim_pulse,y_tx_matched,t_pulse]=trans_obj.get_pulse();
         y_tx_auto=xcorr(y_tx_matched,'normalized');          
         tmp=(nansum(abs(y_tx_auto).^2)/(nanmax(abs(y_tx_auto).^2))).*trans_obj.get_params_value('SampleInterval');
    else
        [tmp,~]=trans_obj.get_pulse_length();
    end
else
    [tmp,~]=trans_obj.get_pulse_length();    
end

trans_obj.Params.TeffCompPulseLength=tmp(:,trans_obj.Params.PingNumber);

end