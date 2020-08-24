function [dr_sp,dr_sv]=compute_dr_corr(type,t_nom,c)
switch type
    case list_WBTs()
        dr_sp = zeros(size(t_nom)) ;
        dr_sv = c(1)*t_nom/4 ;
    case list_GPTs()
        dr_sp = zeros(size(t_nom))  ;
        dr_sv = c(1)*t_nom/4 ;
    case {'ASL'}
        dr_sp=zeros(size(t_nom));
        dr_sv=zeros(size(t_nom));
    case 'CREST'
        dr_sp = c(1)*t_nom/4 ;
        dr_sv = c(1)*t_nom/4 ;
    otherwise
        dr_sp = zeros(size(t_nom)) ;
        dr_sv = c(1)*t_nom/4 ;
end
