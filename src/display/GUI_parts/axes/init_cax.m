function [Cax,Type,Units]=init_cax(Fieldname)

if isempty(Fieldname)
    Cax=[];
    Type='';
    Units='';
    return;
end

switch lower(deblank(Fieldname))
    case 'sv'
        Cax=[-70 -35];
        Type='Sv';
        Units='dB';
    case 'svdenoised'
        Cax=[-70 -35];
        Type='Denoised Sv';
        Units='dB';
    case 'sp'
        Cax=[-60 -30];
        Type='TS (uncomp.)';
        Units='dB';
    case {'sp_comp' 'ts'}
        Cax=[-60 -30];
        Type='TS';
        Units='dB';
    case 'spdenoised'
        Cax=[-60 -30];
        Type='Denoised Sp';
        Units='dB';
    case 'svunmatched'
        Cax=[-60 -30];
        Type='Sv (non-matched)';
        Units='dB';
    case 'spunmatched'
        Cax=[-60 -30];
        Type='TS (uncomp.,non-matched)';
        Units='dB';
    case 'power'
        Cax=[-200 0];
        Type='Power';
        Units='dB';
    case 'powerunmatched'
        Cax=[-200 0];
        Type='Power before match Filtering';
        Units='dB';
    case 'powerdenoised'
        Cax=[-200 0];
        Type='Denoised Power';
        Units='dB';
    case 'y_real'
        Cax=[-200 0];
        Type='Y_real';
        Units='dB';
    case 'y_real_filtered'
        Cax=[-200 0];
        Type='Y_real_filtered';
        Units='dB';
    case'y_imag'
        Cax=[-200 0];
        Type='Y_imag';
        Units='dB';
    case'y_imag_filtered'
        Cax=[-200 0];
        Type='Y_imag_filtered';
        Units='dB';
    case 'singletarget'
        Cax=[-60 -30];
        Type='ST TS';
        Units='dB';
    case 'snr'
        Cax=[0 30];
        Type='SNR';
        Units='dB';
    case 'acrossphi'
        Cax=[-180 180];
        Type='Phase Across';
        Units='dB';
    case 'alongphi'
        Cax=[-180 180];
        Type='Phase Along';
        Units='dB';
    case 'alongangle'
        Cax=[-10 10];
        Type='Angle Along';
        Units=char(hex2dec('00BA'));
    case 'acrossangle'
        Cax=[-10 10];
        Type='Angle Across';
        Units=char(hex2dec('00BA'));
    case 'fishdensity'
        Cax=[0 10];
        Type='Fish Density';
        Units='fish/m^3';
    case 'motioncompensation'
        Cax=[0 12];
        Type='Motion Compensation';
        Units='dB';
    case 'std_sv'
        Cax=[0 12];
        Type='Std Sv';
        Units='dB';
    case 'prc'
        Cax=[0 50];
        Type='PRC';
        Units='%';
    case 'img_intensity'
        Cax=[0 2^8];
        Type='Image Intensity';
        Units ='';
    otherwise
        if contains(lower(Fieldname),'khz')
            Type=['Sv-' Fieldname];
            Cax=[-10 10];
            Units='dB';
        else
            Cax=[-200 200];
            Type=Fieldname;
            Units='dB';
        end
end

end