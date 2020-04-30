function output_struct=bg_noise_removal_v2(trans_obj,varargin)

range_t=trans_obj.get_transceiver_range();

p = inputParser;

defaultv_filt=5;
checkv_filt=@(v_filt)(v_filt>0&&v_filt<=range_t(end));
defaulth_filt=10;
checkh_filt=@(h_filt)(h_filt>0&&h_filt<=1000);
defaultNoiseThr=-125;
checkNoiseThr=@(NoiseThr)(NoiseThr<=-10&&NoiseThr>=-200);
defaultSNRThr=10;
checkSNRThr=@(SNRThr)(SNRThr>=0&&SNRThr<=40);


addRequired(p,'trans_obj',@(obj) isa(obj,'transceiver_cl'));

addParameter(p,'v_filt',defaultv_filt,checkv_filt);
addParameter(p,'h_filt',defaulth_filt,checkh_filt);
addParameter(p,'NoiseThr',defaultNoiseThr,checkNoiseThr);
addParameter(p,'SNRThr',defaultSNRThr,checkSNRThr);
addParameter(p,'reg_obj',region_cl.empty(),@(x) isa(x,'region_cl'));
addParameter(p,'block_len',get_block_len(10,'cpu'),@(x) x>0);
addParameter(p,'load_bar_comp',[]);

parse(p,trans_obj,varargin{:});
output_struct.done=false;

c=trans_obj.get_soundspeed([]);

FreqStart=trans_obj.get_params_value('FrequencyStart',1);
FreqEnd=trans_obj.get_params_value('FrequencyEnd',1);
Freq=trans_obj.Config.Frequency;
ptx=trans_obj.get_params_value('TransmitPower',[]);

eq_beam_angle=trans_obj.Config.EquivalentBeamAngle;
gain=trans_obj.get_current_gain();

FreqCenter=(FreqStart+FreqEnd)/2;

eq_beam_angle=eq_beam_angle+20*log10(Freq./(FreqCenter));
alpha=trans_obj.get_absorption();
cal=trans_obj.get_cal();
sacorr=2*cal.SACORRECT;

pings_tot=trans_obj.get_transceiver_pings();

if strcmp(trans_obj.Mode,'FM')
    [t_eff,~]=trans_obj.get_pulse_comp_Teff();
else
    [t_eff,~]=trans_obj.get_pulse_Teff();
end

[t_nom,~]=trans_obj.get_pulse_length();

nb_pings_tot=numel(pings_tot);

block_size=ceil(p.Results.block_len/numel(range_t));

num_ite=ceil(nb_pings_tot/block_size);

if ~isempty(p.Results.load_bar_comp)
    set(p.Results.load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',num_ite, 'Value',0);
end
output_struct.done=false;
idx_pings_tot=1:nb_pings_tot;
idx_r=1:numel(range_t);

for ui=1:num_ite
    idx_pings=idx_pings_tot((ui-1)*block_size+1:nanmin(ui*block_size,numel(idx_pings_tot)));
    sub_bot=trans_obj.get_bottom_range(idx_pings);
    
    lambda=c./FreqCenter;
    
    reg_temp=region_cl('Name','Temp','Idx_r',idx_r,'Idx_pings',idx_pings);
    [pow,idx_r,idx_pings,bad_data_mask,bad_trans_vec,~,below_bot_mask,~]=get_data_from_region(trans_obj,reg_temp,'field','power');
    
    if isempty(pow)
        return;
    end
    
    pow(bad_data_mask)=nan;
    pow(pow==0)=nan;
    pow(range_t<0.1*nanmax(range_t),:)=nan;
    
    [nb_samples,nb_pings]=size(pow);
    
    [I,J]=find(~isnan(pow));
   
    J_d=[J ; J ];
    I_d=[I ; ceil(0.9*I)];
    
    idx_d=I_d+nb_samples*(J_d-1);
    reg_n=false(nb_samples,nb_pings);
    reg_n(idx_d)=true;
 
    v_filt_m=nanmax(p.Results.v_filt,3*nanmax(diff(range_t)));
    
    v_filt=ceil(nanmin(v_filt_m,size(pow,1))/nanmax(diff(range_t)));
    
    h_filt=ceil(nanmin(p.Results.h_filt,size(pow,2)/20));
    noise_thr=p.Results.NoiseThr;
    SNR_thr=p.Results.SNRThr;
    
    pow_filt=filter2_perso(ones(v_filt,h_filt),pow);
    
    pow_filt(pow_filt==0|~reg_n)=nan;
    [noise_db,~]=nanmin(10*log10(pow_filt),[],1);
    
    pow_noise_db=bsxfun(@times,noise_db,ones(size(pow,1),1));
    pow_noise_db(pow<0)=nan;
    pow_noise_db(pow_noise_db>noise_thr)=noise_thr;
    
    pow_noise=10.^(pow_noise_db/10);
%     pow_unoised=pow-pow_noise;
%     pow_unoised(pow_unoised<=0)=nan;
%     
    [sv,~,~,~,~,~,~,~]=get_data_from_region(trans_obj,reg_temp,'field','sv');
    [sp,~,~,~,~,~,~,~]=get_data_from_region(trans_obj,reg_temp,'field','sp');
    
    sp=db2pow_perso(sp);
    sv=db2pow_perso(sv);
    
    [sp_noise,sv_noise]=convert_power_v2(pow_noise,range_t,c,alpha,t_eff(idx_pings),t_nom(idx_pings),double(ptx(idx_pings)),lambda,gain,eq_beam_angle,sacorr,trans_obj.Config.TransceiverName);
    
    sp_noise=db2pow_perso(sp_noise);
    sv_noise=db2pow_perso(sv_noise);
    
    
    Sp_unoised_lin=sp-sp_noise;
    Sp_unoised_lin(Sp_unoised_lin<=0)=nan;
    Sp_unoised=10*log10(Sp_unoised_lin);
    
    
    Sv_unoised_lin=sv-sv_noise;
    Sv_unoised_lin(Sv_unoised_lin<=0)=nan;
    Sv_unoised=10*log10(Sv_unoised_lin);
    
    
    SNR=Sv_unoised-pow2db_perso(sv_noise);
    %SNR_2=pow2db_perso(pow_unoised./pow_noise);
    %pow_unoised(SNR<SNR_thr)=0;
    Sp_unoised(SNR<SNR_thr)=-999;
    Sv_unoised(SNR<SNR_thr)=-999;
    
    %pow_unoised(isnan(pow_unoised))=0;
    Sp_unoised(isnan(Sp_unoised))=-999;
    Sv_unoised(isnan(Sv_unoised))=-999;
    SNR(isnan(SNR))=-999;
    
    
    %trans_obj.Data.replace_sub_data_v2('powerdenoised',pow_unoised,[],idx_pings,);
    trans_obj.Data.replace_sub_data_v2('spdenoised',Sp_unoised,[],idx_pings);
    trans_obj.Data.replace_sub_data_v2('svdenoised',Sv_unoised,[],idx_pings);
    trans_obj.Data.replace_sub_data_v2('snr',SNR,[],idx_pings);
    clear Sp_unoised Sv_unoised snr pow
    if ~isempty(p.Results.load_bar_comp)
        set(p.Results.load_bar_comp.progress_bar, 'Value',ui);
    end
    
end
output_struct.done=true;

end



