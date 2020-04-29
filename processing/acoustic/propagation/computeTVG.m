function [TVG_Sp,TVG_Sv,range_sp,range_sv]=computeTVG(range,dr_sp,dr_sv)

range_sp=range-dr_sp;
range_sp(range_sp<0)=0;

range_sv=range-dr_sv;
range_sv(range_sv<0)=0;

TVG_Sp = real(40*log10(range_sp));
TVG_Sp(TVG_Sp<0)=0;

TVG_Sv =real(20*log10(range_sv));
TVG_Sv(TVG_Sv<0)=0;

end