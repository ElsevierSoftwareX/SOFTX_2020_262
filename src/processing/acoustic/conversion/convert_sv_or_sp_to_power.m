function power=convert_sv_or_sp_to_power(sp_or_sv,range,c,alpha,t_eff,t_nom,ptx,lambda,gain,eq_beam_angle,sacorr,type,val)

[dr_sp,dr_sv]=compute_dr_corr(type,t_nom,c);

[TVG_Sp,TVG_Sv,range_sp,range_sv]=computeTVG(range,dr_sp,dr_sv);

switch val
    case 'sp'
        tmp=sp_or_sv-(TVG_Sp+2*alpha.*range_sp);
    case 'sv'
        tmp=sp_or_sv-(-10*log10(c*t_eff/2)-eq_beam_angle-2*sacorr+TVG_Sv+2*alpha.*range_sv);
end

switch type
    case {'FCV30'}
        power=db2pow(tmp+2*gain); 
    case {'ASL'}  
        power=db2pow(tmp); 
    otherwise
        power=db2pow(tmp-(-2*gain-10*log10(ptx.*lambda.^2/(16*pi^2))));        
end

end


