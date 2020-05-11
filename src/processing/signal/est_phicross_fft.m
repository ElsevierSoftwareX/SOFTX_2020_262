function [n_fft_eval,delta_deg,estim_ph_deg,phi_est_deg]=est_phicross_fft(n,amp,phase_deg,phi_fix)

phase=phase_deg/180*pi;
n=n-n(1)+1;
nfft=nanmax(2^(nextpow2(length(amp))+1),2^14);

S=abs(fft(amp.*exp(1i*phase),nfft)).^2;

[~,idx_freq]=max(fftshift(S));

estim_ph=2*pi*(idx_freq-((nfft)/2+1))/(nfft);
estim_ph_deg=estim_ph/pi*180;

sig_comp_tmp=amp.*exp(1i*phase);
sig_comp=sig_comp_tmp.*exp(-1i*estim_ph*n);

phi_const = angle(nanmean(sig_comp));

phi_est=estim_ph*n+phi_const;

[~,idx_amp]=max(amp);

k=round((phase(idx_amp)-phi_est(idx_amp))/(pi));

phi_est=phi_est+k*pi;

delta=sqrt(nanmean(angle((exp(1i*phi_est(amp>nanmax(amp/10))).*exp(-1i*phase(amp>nanmax(amp/10))))).^2));
delta_deg=delta/pi*180;

phi_est_deg=phi_est/pi*180;

% figure();clf;plot(fftshift(S))
% figure();clf;plot(phi_est);hold on;plot(phase);

n_fft_eval=nan(1,length(phi_fix));

for i=1:length(phi_fix)
    n_fft_eval(i)=(phi_fix(i)-(phi_const+2*k*pi))/estim_ph;
end

end