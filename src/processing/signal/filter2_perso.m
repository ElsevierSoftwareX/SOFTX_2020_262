function C=filter2_perso(B,A)


idx_nan=isnan(A);
A(idx_nan)=0;

nan_filt=filter2(B,double(~idx_nan));
ori_filt=filter2(B,A);
C=ori_filt./nan_filt;


end