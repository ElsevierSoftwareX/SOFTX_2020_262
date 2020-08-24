function [Sp,Sv]=convert_power_v2(power,range,c,alpha,t_eff,t_nom,ptx,lambda,gain,eq_beam_angle,sacorr,type)


if numel(size(power))>2
    gain = shiftdim(gain,-1);
    ptx = shiftdim(ptx,-1);
    lambda = shiftdim(lambda,-1);
    eq_beam_angle = shiftdim(eq_beam_angle,-1);
    t_eff = shiftdim(t_eff,-1);
    t_nom = shiftdim(t_nom,-1);
end

[dr_sp,dr_sv]=compute_dr_corr(type,t_nom,c);
[TVG_Sp,TVG_Sv,range_sp,range_sv]=computeTVG(range,dr_sp,dr_sv);

switch type
    case {'FCV30'}
        tmp=10*log10(single(power))-2*gain;     
    case {'ASL'}
        tmp=10*log10(single(power));
        sacorr=0;
    otherwise
        tmp=10*log10(single(power))-2*gain-10*log10(ptx.*lambda.^2/(16*pi^2));   
end

if numel(unique(alpha))>1
    Sp=tmp+TVG_Sp+2*cumsum(alpha.*[zeros(1,size(range_sp,2));diff(range_sp,1)],1);
    Sv=tmp-10*log10(c.*t_eff/2)-eq_beam_angle-2*sacorr+TVG_Sv+2*cumsum(alpha.*[zeros(1,size(range_sv,2)); diff(range_sv,1)],1);
else
    alpha=(unique(alpha));
    Sp=tmp+TVG_Sp+2*alpha.*range_sp;
    Sv=tmp-10*log10(c.*t_eff/2)-eq_beam_angle-2*sacorr+TVG_Sv+2*alpha.*range_sv;
end
end

        
        