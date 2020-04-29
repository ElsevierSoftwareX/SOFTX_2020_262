function set_pulse_comp_Teff(trans_obj)

if ~isempty(trans_obj.Filters)
    if trans_obj.Filters(1).DecimationFactor>0
        [~,y_tx_matched]=generate_sim_pulse(trans_obj.Params,trans_obj.Filters(1),trans_obj.Filters(2));
         y_tx_auto=xcorr(y_tx_matched,'normalized');          
         trans_obj.Params.TeffCompPulseLength=(nansum(abs(y_tx_auto).^2)/(nanmax(abs(y_tx_auto).^2))).*trans_obj.Params.SampleInterval();
    else
        [trans_obj.Params.TeffCompPulseLength,~]=trans_obj.get_pulse_length();
    end
else
    [trans_obj.Params.TeffCompPulseLength,~]=trans_obj.get_pulse_length();    
end



end