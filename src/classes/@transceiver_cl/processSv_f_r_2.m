function [Sv_f,f_vec,r]=processSv_f_r_2(trans_obj,EnvData,iPing,r,nfft,cal,att_model,output_size,cell_h)

if isempty(att_model)
    att_model='doonan';
end



if strcmp(trans_obj.Mode,'FM')
    
    if isempty(cal)
        cal=trans_obj.get_fm_cal('');
    end
    
    Rwt_rx=trans_obj.Config.Impedance;
    Ztrd=trans_obj.Config.Ztrd;
    nb_chan=trans_obj.Config.NbQuadrants;
    
    f_s_sig=round((1/(trans_obj.get_params_value('SampleInterval',iPing))));
    c=(EnvData.SoundSpeed);
    FreqStart=(trans_obj.get_params_value('FrequencyStart',iPing));
    FreqEnd=(trans_obj.get_params_value('FrequencyEnd',iPing));
    
    if FreqEnd>=120000||FreqStart>=120000
        att_model='fandg';
    end
    
    
    ptx=(trans_obj.get_params_value('TransmitPower',iPing));
    [pulse_length,~]=trans_obj.get_pulse_length(iPing);
    
    %eq_beam_angle=trans_obj.Config.EquivalentBeamAngle;

    
    range=trans_obj.get_transceiver_range();
    nb_samples=length(range);
    Np=2^nextpow2(ceil(pulse_length*f_s_sig)+1);
    
    if isempty(nfft)
        nfft=nanmax(length(r),Np);
        nfft=2^(nextpow2(nfft));
    else
        nfft=2^(nextpow2(nfft));
    end
    
    [~,idx_r1]=nanmin(abs(range-(r(1))));
    [~,idx_r2]=nanmin(abs(range-(r(end))));
    
    idx_r1=nanmax(idx_r1,1);
    idx_r2=nanmin(idx_r2,nb_samples);
    
    %fprintf('%s\n%.0fkHz: FFT win: %.0f, Sig length: %.0f\n' ,output_size,f_nom/1e3,nfft,numel(y_spread));
    %n_cell=nanmin(nanmax(floor(cell_h/dr),1),nfft);
    switch output_size
        case '2D'
            n_overlap=1;
            if (idx_r2-idx_r1)<nfft
                idx_r=round((idx_r1+idx_r2)/2);
                idx_r1=nanmax(idx_r-nfft/2,1);
                idx_r2=nanmin(idx_r1+nfft-1,nb_samples);
            end
        case'3D'
            idx_r1=nanmax(idx_r1-nfft/2+1,1);
            idx_r2=nanmin(idx_r2+nfft/2,nb_samples);
            if cell_h==0
                n_overlap=nfft-1;
            else
                %n_overlap=nanmin(n_cell+nfft/2,nfft-1);
                n_overlap=nfft-1;
            end
    end
    
    y_c=trans_obj.Data.get_subdatamat(idx_r1:idx_r2,iPing,'field','y_real_filtered')+1i*trans_obj.Data.get_subdatamat(idx_r1:idx_r2,iPing,'field','y_imag_filtered');
    if isempty(y_c)
        y_c=trans_obj.Data.get_subdatamat(idx_r1:idx_r2,iPing,'field','y_real')+1i*trans_obj.Data.get_subdatamat(idx_r1:idx_r2,iPing,'field','y_imag');
    end
    
    nfft=min(nfft,numel(y_c));
    
    n_rep=ceil(nanmax(FreqEnd,FreqStart)/f_s_sig);
    f_vec_rep=f_s_sig*(0:nfft*n_rep-1)/nfft;
    
%     if FreqStart>FreqEnd
%         f_vec_rep=fliplr(f_vec_rep);
%     end
    
    idx_vec=f_vec_rep>=nanmin(FreqStart,FreqEnd)&f_vec_rep<=nanmax(FreqStart,FreqEnd);
    %idx_vec=f_vec_rep>=FreqStart&f_vec_rep<=FreqEnd;
    f_vec=f_vec_rep(idx_vec);
        
    r=range(idx_r1:idx_r2);
    
    y_spread=y_c.*r;
    
    w_h=hann(nfft);
    w_h=w_h/(sqrt(nansum(w_h))/sqrt(nfft));
    
    fft_vol = spectrogram(y_spread,w_h,n_overlap,nfft)/nfft;%/nansum(w_h)*nfft;
    
    [~,y_tx_matched]=generate_sim_pulse(trans_obj.Params,trans_obj.Filters(1),trans_obj.Filters(2));
    
    y_tx_auto=xcorr(y_tx_matched)/nansum(abs(y_tx_matched).^2);
    
    if nfft<length(y_tx_auto)
        y_tx_auto_red=y_tx_auto(ceil(length(y_tx_auto)/2)-floor(nfft/2)+1:ceil(length(y_tx_auto)/2)-floor(nfft/2)+nfft);
    else
        y_tx_auto_red=y_tx_auto;
    end
    
    fft_pulse=(fft(y_tx_auto_red,nfft))/nfft;
    
    fft_vol_norm=bsxfun(@rdivide,fft_vol,(fft_pulse));
    
    fft_vol_norm_rep=repmat(fft_vol_norm,n_rep,1);
    
    fft_vol_norm=fft_vol_norm_rep(idx_vec,:)';
      
    if size(fft_vol_norm,1)==1
        r=nanmean(r);
    else
        idx_val=nfft/2+(0:size(fft_vol_norm,1)-1)*(nfft-n_overlap);
        r=r(idx_val);
    end
    switch trans_obj.Config.TransceiverName
        case 'TOPAS'
            
            Sv_f=20*log10(abs(fft_vol_norm));
            idx_val=floor(nfft/2):floor(nfft/2)+size(Sv_f,1)-1;
            r=r(idx_val);
        otherwise
            
            alpha_f = arrayfun(@(x) seawater_absorption(x, EnvData.Salinity, EnvData.Temperature, r,att_model),f_vec/1e3,'un',0);
            alpha_f=cell2mat(alpha_f);
            alpha_f=alpha_f/1e3;
            
            lambda=c./(f_vec);
                        
            eq_beam_angle=interp1(cal.Frequency,cal.eq_beam_angle,f_vec,'linear','extrap');

            Gf=interp1(cal.Frequency,cal.Gain,f_vec,'linear','extrap');

            Prx_fft_vol=nb_chan*(abs(fft_vol_norm)/(2*sqrt(2))).^2*((Rwt_rx+Ztrd)/Rwt_rx)^2/Ztrd;
            
            tw=nfft/f_s_sig;
            
            % Sv_f=10*log10(Prx_fft_vol(:))+2*alpha_f(:).*r-10*log10(c*tw)-10*log10(ptx*lambda(:).^2/(16*pi^2))-2*(Gf(:))-eq_beam_angle(:);
            Sv_f=bsxfun(@minus,10*log10(Prx_fft_vol)+bsxfun(@times,2*alpha_f,r),10*log10(c*tw/2)+10*log10(ptx*lambda.^2/(16*pi^2))+2*Gf+eq_beam_angle);
    end
%     df=nanmean(abs(diff(f_vec)));
%     ds=round(2e3/df);
%     if rem(ds,2)==1
%         ds=ds+1;
%     end
        
%     if ds<size(Sv_f,2)
%         tmp=smoothdata(Sv_f,2,'rlowess',ds);
%         
%         tmp(isnan(Sv_f))=nan;
%         
%         Sv_f=tmp;
%     end
    
else
    Sv_f=[];
    f_vec=[];
    r=[];
    fprintf('%s not in  FM mode\n',trans_obj.Config.ChannelID);
end
r=r(:);

end
