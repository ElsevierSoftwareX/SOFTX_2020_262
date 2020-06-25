 function [Sp_f,compensation_f,f_vec,r_tot,f_corr]=processTS_f_v2(trans_obj,EnvData,iPing,r,cal,att_model)

range_tr=trans_obj.get_transceiver_range();
[~,idx_ts_min]=nanmin(abs(range_tr-nanmin(r)));
[~,idx_ts_max]=nanmin(abs(range_tr-nanmax(r)));

if strcmp(trans_obj.Mode,'FM')
    if isempty(cal)
        cal=trans_obj.get_fm_cal();
    end
    
    Rwt_rx=trans_obj.Config.Impedance;
    Ztrd=trans_obj.Config.Ztrd;
    nb_chan=trans_obj.Config.NbQuadrants;
    
    f_s_sig=round(1/(trans_obj.get_params_value('SampleInterval',iPing)));
    c=(EnvData.SoundSpeed);
    FreqStart=(trans_obj.get_params_value('FrequencyStart',iPing));
    FreqEnd=(trans_obj.get_params_value('FrequencyEnd',iPing));
    
    if FreqEnd>=120000||FreqStart>=120000
        att_model='fandg';
    end
     
    ptx=(trans_obj.get_params_value('TransmitPower',iPing));
    [~,Np]=trans_obj.get_pulse_length(iPing);
    
    nfft=2^(nextpow2(Np));
    
    idx_ts=(idx_ts_min-nfft/2):(idx_ts_max+nfft/2-1);
    
    idx_ts=idx_ts(1:nanmin(length(r)*nfft,length(idx_ts)));
    
    idx_ts=idx_ts+nansum(idx_ts<=0);
    idx_ts=idx_ts-nansum(idx_ts>numel(range_tr));
    
    y_c_ts=trans_obj.Data.get_subdatamat(idx_ts,iPing,'field','y_real_filtered')+1i*trans_obj.Data.get_subdatamat(idx_ts,iPing,'field','y_imag_filtered');
    if isempty(y_c_ts)
        y_c_ts=trans_obj.Data.get_subdatamat(idx_ts,iPing,'field','y_real')+1i*trans_obj.Data.get_subdatamat(idx_ts,iPing,'field','y_imag');
    end
    
    nfft=min(nfft,numel(y_c_ts));
    
    AlongAngle_val=trans_obj.Data.get_subdatamat(idx_ts,iPing,'field','AlongAngle');
    AcrossAngle_val=trans_obj.Data.get_subdatamat(idx_ts,iPing,'field','AcrossAngle');
    
    r_ts=range_tr(idx_ts);
    
    [~,y_tx_matched]=generate_sim_pulse(trans_obj.Params,trans_obj.Filters(1),trans_obj.Filters(2));
        
    y_tx_auto=xcorr(y_tx_matched)/nansum(abs(y_tx_matched).^2);
    
    if nfft<length(y_tx_auto)
        y_tx_auto_red=y_tx_auto(ceil(length(y_tx_auto)/2)-floor(nfft/2)+1:ceil(length(y_tx_auto)/2)-floor(nfft/2)+nfft);
    else
        y_tx_auto_red=y_tx_auto;
    end
        
    fft_pulse=(fft(y_tx_auto_red,nfft))/nfft;
    
    win=hann(nfft);
    win=win/(sqrt(nansum(win))/sqrt(nfft));
    
    s = spectrogram(y_c_ts,win,nfft-1,nfft)/nfft;
    
    s_norm=bsxfun(@rdivide,s,fft_pulse);
    
    n_rep=ceil(nanmax(FreqEnd,FreqStart)/f_s_sig);
    
    f_vec_rep=f_s_sig*(0:nfft*n_rep-1)/nfft;
    
    s_norm_rep=repmat(s_norm,n_rep,1);
    
    idx_vec=f_vec_rep>=nanmin(FreqStart,FreqEnd)&f_vec_rep<=nanmax(FreqStart,FreqEnd);
    f_vec=f_vec_rep(idx_vec);
    
    
    s_norm=s_norm_rep(idx_vec,:)';
    
    if size(s_norm,1)>1
        idx_val=floor(nfft/2):floor(nfft/2)+size(s_norm,1)-1;
    else
        [~,idx_val]=nanmax(abs(y_c_ts));
    end
    
    
    r_tot=r_ts(idx_val);
    
    if ~isempty(AlongAngle_val)
        AlongAngle_val=AlongAngle_val(idx_val);
        AcrossAngle_val=AcrossAngle_val(idx_val);
    end
    
    %eq_beam_angle_f=eq_beam_angle-20*log10(f_vec/Freq);
    
    %     BeamWidthAlongship_f=trans_obj.Config.BeamWidthAlongship*acos(1-(10.^(eq_beam_angle_f/10))/(2*pi))/acos(1-(10.^(eq_beam_angle/20))/(2*pi));
    %     BeamWidthAthwartship_f=trans_obj.Config.BeamWidthAthwartship*acos(1-(10.^(eq_beam_angle_f/10))/(2*pi))/acos(1-(10.^(eq_beam_angle/20))/(2*pi));
    %
    
    
    BeamWidthAlongship=interp1(cal.Frequency,cal.BeamWidthAlongship,f_vec,'linear','extrap');
    BeamWidthAthwartship=interp1(cal.Frequency,cal.BeamWidthAthwartship,f_vec,'linear','extrap');
    
    Gf=interp1(cal.Frequency,cal.Gain,f_vec,'linear','extrap');
      
    alpha_f = arrayfun(@(x) seawater_absorption(x, EnvData.Salinity, EnvData.Temperature, r_tot,att_model),f_vec/1e3,'un',0);
    alpha_f=cell2mat(alpha_f);
    alpha_f=alpha_f/1e3;
    
    Prx_fft=nb_chan/2*(abs(s_norm)/(2*sqrt(2))).^2*((Rwt_rx+Ztrd)/Rwt_rx)^2/Ztrd;
    
    %correction factor based on frequency response of targets to acount for
    %positionning "error", not sure so not applying it...
    %f_corr=nansum((1+(f_nom-f_vec)/f_nom).*Prx_fft.^2)/nansum(Prx_fft.^2);
    
    f_corr=1;
    if ~isempty(AlongAngle_val)
        AlongAngle_val_corr=AlongAngle_val/f_corr;
        AcrossAngle_val_corr=AcrossAngle_val/f_corr;
        
        compensation_f =arrayfun(@(x,y)  simradBeamCompensation(x,y, AlongAngle_val_corr,AcrossAngle_val_corr),BeamWidthAlongship,BeamWidthAthwartship,'un',0);
        compensation_f=cell2mat(compensation_f);
    else
        compensation_f = zeros(size(f_vec));
    end
    
    %     compensation_f(compensation_f<0)=nan;
    %     compensation_f(compensation_f>12)=nan;
    %
    

    
    lambda=c./(f_vec);
%     df=nanmean(abs(diff(f_vec)));
    
%     
%     ds=round(1e3/df);
%     if rem(ds,2)==1
%         ds=ds+1;
%     end
%     
    Sp_f=bsxfun(@minus,bsxfun(@plus,10*log10(Prx_fft)+bsxfun(@times,2*alpha_f,r_tot),40*log10(r_tot)),10*log10(ptx*lambda.^2/(16*pi^2))+2*(Gf));
    
    
%     if ds<size(Sp_f,2)
%         tmp=smoothdata(Sp_f,2,'rlowess',ds);
%         tmp=smooth(Sp_f,ds,'rlowess');
%         
%         tmp(isnan(Sp_f))=nan;
%         %             figure();
%         %             plot(f_vec/1e3,tmp);hold on;
%         %             plot(f_vec/1e3,Sp_f(i,:));
%         Sp_f=tmp;
%     end
    

else

    idx_r=idx_ts_min:idx_ts_max;
    r_tot=range_tr(idx_r);
    f_corr=ones(size(idx_r));
    BeamWidthAlongship=trans_obj.Config.BeamWidthAlongship;
    BeamWidthAthwartship=trans_obj.Config.BeamWidthAthwartship;
    
    f_vec=trans_obj.get_params_value('Frequency',iPing);
    Sp_f=trans_obj.Data.get_subdatamat(idx_r,iPing,'field','spdenoised');
    if isempty(Sp_f)
        Sp_f=trans_obj.Data.get_subdatamat(idx_r,iPing,'field','sp');
    end
    ac_angle=trans_obj.Data.get_subdatamat(idx_r,iPing,'field','AcrossAngle');
    al_angle=trans_obj.Data.get_subdatamat(idx_r,iPing,'field','AlongAngle');
    
    if ~isempty(ac_angle)
        compensation_f=simradBeamCompensation(BeamWidthAlongship,BeamWidthAthwartship , ac_angle, al_angle);
    else
        compensation_f=zeros(size(Sp_f));
    end
    

    
end

end
