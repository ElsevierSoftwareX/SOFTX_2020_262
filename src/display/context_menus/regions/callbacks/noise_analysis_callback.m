function noise_analysis_callback(~,~,select_plot,main_figure)

layer=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');
[trans_obj,idx_freq]=layer.get_trans(curr_disp);



switch class(select_plot)
    case 'region_cl'
        reg_curr=select_plot;
    otherwise
        idx_pings=round(nanmin(select_plot.XData)):round(nanmax(select_plot.XData));
        idx_r=round(nanmin(select_plot.YData)):round(nanmax(select_plot.YData));
        reg_curr=region_cl('Idx_pings',idx_pings,'Idx_r',idx_r);
end

data=trans_obj.Data.get_subdatamat(reg_curr.Idx_r,reg_curr.Idx_pings,'field','power');

fs=1./trans_obj.get_params_value('SampleInterval',reg_curr.Idx_pings)/2;


[nb_samples,nb_pings]=size(data);

nfft=2^(nextpow2(nb_samples)+1);
ffts=nan(nfft,nb_pings);

f_vec=nan(nfft,nb_pings);

for i=1:nb_pings
    ffts(:,i)=fftshift(fft(data(:,i),nfft)/sqrt(nfft*fs(i)));
    f_vec(:,i)=fs(i)*((0:(nfft-1))/nfft-1/2);
end

[fs_unique,idx_unique]=unique(fs);

nb_fig=length(fs_unique);

for i=1:nb_fig
    idx_fs=idx_unique==i;
    P_f=10*log10(2*(nanmean(ffts(:,idx_fs).*conj(ffts(:,idx_fs)),2)));

    h=new_echo_figure(main_figure,'Tag',sprintf('pf%f%f',reg_curr.ID,fs_unique(i)),'Tag','noise_analysis','Toolbar','esp3','MenuBar','esp3');
    ah=axes(h);
    plot(ah,nanmean(f_vec(:,idx_fs),2),P_f);
    grid(ah,'on');
    ylabel(ah,'|P(f)| (dB/Hz)');
    title(ah,[sprintf('%s\n',trans_obj.Config.ChannelID) sprintf('Regions %.0f Bandwidth %.0f Hz, Frequency resolution %.2fHz',reg_curr.ID,fs_unique(i),fs_unique(i)/nfft)]);  
    ah.XAxis.TickLabelRotation=90;
    ah.XAxis.ExponentMode='manual';
    ah.XAxis.Exponent=0;
    ah.XAxis.TickLabelFormat  = '%.0f Hz';

end




end