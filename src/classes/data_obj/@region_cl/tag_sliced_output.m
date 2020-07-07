function cell_tags=tag_sliced_output(reg_obj,sliced_output,select)

if~iscell(sliced_output)
    sliced_output={sliced_output};
end

cell_tags=cell(1,numel(sliced_output));

for ui=1:numel(sliced_output)
    if istall(sliced_output{ui}.eint)
        eint = gather(sliced_output{ui}.eint);
        sample_E = gather(sliced_output{ui}.Sample_E);
        sample_S = gather(sliced_output{ui}.Sample_S);
    else
        eint = sliced_output{ui}.eint;
        sample_E = sliced_output{ui}.Sample_E;
        sample_S = sliced_output{ui}.Sample_S;
    end
    s_eint = size(eint);
    cell_tags{ui}=strings(s_eint);
    idx_tag=false(s_eint);
    
    for ir=1:numel(reg_obj)
        if strcmpi(reg_obj(ir).Name,'WC')||strcmpi(reg_obj(ir).Type,'Bad Data')
            continue;
        end
        poly =reg_obj(ir).Poly;
        xp=poly.Vertices(:,1);
        yp=poly.Vertices(:,2);
        idx_in_tot=false(s_eint);
        
        switch select
            case 'all'
                
                [idx_in,idx_on]=inpolygon(repmat(sliced_output{ui}.Ping_E,s_eint(1),1),...
                    sample_E,xp,yp);
                idx_in_tot=idx_in_tot|((idx_on|idx_in));
                
                [idx_in,idx_on]=inpolygon(repmat(sliced_output{ui}.Ping_S,s_eint(1),1),...
                    sample_S,xp,yp);
                
                idx_in_tot=idx_in_tot|((idx_on|idx_in));
                
                [idx_in,idx_on]=inpolygon(repmat(sliced_output{ui}.Ping_E,s_eint(1),1),...
                    sample_S,xp,yp);
                
                idx_in_tot=idx_in_tot|((idx_on|idx_in));
                [idx_in,idx_on]=inpolygon(repmat(sliced_output{ui}.Ping_S,s_eint(1),1),...
                    sample_E,xp,yp);
                
                idx_in_tot=idx_in_tot|((idx_on|idx_in));
                
            case 'in'
                [idx_in,idx_on]=inpolygon(repmat((sliced_output{ui}.Ping_E+sliced_output{ui}.Ping_S)/2,s_eint(1),1),(sample_S+sample_E)/2,xp,yp);
                idx_in_tot=idx_in_tot|((idx_on|idx_in));
                
        end
        idx_in_tot=idx_in_tot&eint>0;
        
        if any(idx_tag(idx_in_tot))
            disp_perso([],'WARNING: Found overlapping regions while tagging sliced transect...');
            disp_perso([],'Ignore this warning if you are not using a integration using tagged cells');
        end
        
        idx_tag(idx_in_tot)=true;
        cell_tags{ui}(idx_in_tot)=reg_obj(ir).Tag;
    end
    
    
end

end