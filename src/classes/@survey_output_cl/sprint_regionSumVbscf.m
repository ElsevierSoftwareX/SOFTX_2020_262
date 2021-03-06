function str=sprint_regionSumVbscf(surv_out_obj)
regionSumVbscf=surv_out_obj.regionSumVbscf;

str=sprintf('\n# Region vbscf\n#snapshot type stratum transect file region_id num_h_slices num_v_slices region_vbscf vbscf_values\n');

prec={'%0.f,' '%s,' '%s,' '%0.f,' '%s,' '%0.f,' '%0.f,' '%0.f,' '%.5e,'};

fields=fieldnames(regionSumVbscf);

for k = 1:length(regionSumVbscf.snapshot)
    
    for iu=1:length(prec)
        switch fields{iu}
            case 'file'
                for ifs=1:length(regionSumVbscf.(fields{iu}){k})
                    [~,file,~]=fileparts(regionSumVbscf.(fields{iu}){k}{ifs});
                    if ifs>1
                        str=[str ';' file];
                    else
                        str=[str file];
                    end
                end
                str=[str ','];
            otherwise
                
                if iscell(regionSumVbscf.(fields{iu}))
                    if ~iscell(regionSumVbscf.(fields{iu}){k})
                        str=[str sprintf(prec{iu}, regionSumVbscf.(fields{iu}){k})];
                    else
                        str=[str sprintf(prec{iu}, cell2mat(regionSumVbscf.(fields{iu}){k}))];
                    end
                else
                    str=[str sprintf(prec{iu}, regionSumVbscf.(fields{iu})(k))];
                end
        end
    end
    vb=regionSumVbscf.vbscf_values{k}';
    vb=vb(:);
    for ik=1:length(vb)
        if vb(ik)==0||isnan(vb(ik))
            precslice_abscf='%.0f,';
            str=[str sprintf(precslice_abscf, 0)];
        else
            precslice_abscf='%.5e,';
            str=[str sprintf(precslice_abscf, vb(ik))];
        end
        
    end
    str=str(1:end-1);
    str=[str sprintf('\n')];
end
end
