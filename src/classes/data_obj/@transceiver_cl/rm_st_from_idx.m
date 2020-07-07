function rm_st_from_idx(trans_obj,idx_p,idx_r)
range_t=trans_obj.get_transceiver_range();

idx_r=idx_r(:)';
idx_p=idx_p(:)';
idx_targets_lin=idx_r+(idx_p-1)*numel(range_t);

single_targets_tot=trans_obj.ST;
fields_st=fieldnames(single_targets_tot);

[~,idx_rm,~]=intersect(single_targets_tot.idx_target_lin,idx_targets_lin);

if ~isempty(idx_rm)
    for ifi=1:numel(fields_st)
        if numel(single_targets.(fields_st{ifi}))==numel(trans_obj.ST.Ping_number)
            single_targets_tot.(fields_st{ifi})(idx_rm)=[];
        end
    end
   
    
    trans_obj.set_ST(single_targets_tot);
end
end