function [Z,x_vals]=compute_ping_impedance(trans_obj,iPing)

signals=trans_obj.TransducerImpedance(:,iPing);

[~,Np]=trans_obj.get_pulse_length(iPing);
Np=Np-8;
%f_s_sig=round(1/(trans_obj.get_params_value('SampleInterval',iPing)));
%f_vec_based=linspace(-f_s_sig/2,f_s_sig/2,Np);

FreqStart=(trans_obj.get_params_value('FrequencyStart',iPing));
FreqEnd=(trans_obj.get_params_value('FrequencyEnd',iPing));

f_vec_pulse=linspace(FreqStart,FreqEnd,Np);

%f_vec_pulse_based=f_vec_pulse-f_s_sig;
%  f_s_sig/abs(FreqEnd-FreqStart)
%  Np

switch trans_obj.Mode
    case 'FM'
        idx_keep=(1:Np)+round(Np/2)-round(Np/13)+10;
    otherwise
        idx_keep=(1:Np);
end


Z=cell(1,numel(signals));
x_vals=cell(1,numel(signals));
for isig=1:numel(signals)
    
    tmp_real=uint32(typecast(single(real(signals{isig})),'uint16'));
    tmp=cellfun(@(x) dec2bin(x*2^16,32),num2cell(tmp_real),'un',0);
    tmp_real=cellfun(@mantissa2single,tmp);
    
    
    tmp_imag=uint32(typecast(single(imag(signals{isig})),'uint16'));
    tmp=cellfun(@(x) dec2bin(x*2^16,32),num2cell(tmp_imag),'un',0);
    tmp_imag=cellfun(@mantissa2single,tmp);
    
    sig_tmp=(tmp_real(2:2:end)+1i*tmp_imag(2:2:end))./(tmp_real(1:2:end)+1i*tmp_imag(1:2:end));
    if ~isempty(sig_tmp)
        Z{isig}=sig_tmp(idx_keep);
        
        switch trans_obj.Mode
            case 'FM'
                x_vals{isig}=f_vec_pulse;
            otherwise
                x_vals{isig}=idx_keep;
        end
        %x_vals{isig}=idx_keep;
    else
        x_vals{isig}=[];
        Z{isig}=[];
    end
end


end

