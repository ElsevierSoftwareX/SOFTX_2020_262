function set_ST(trans_obj,ST)

block_len=get_block_len(100,'cpu');

trans_obj.Data.replace_sub_data_v2(-999,'field','singletarget');

if ~isempty(ST)&&~isempty(ST.Ping_number)
    [~,np]=trans_obj.get_pulse_Teff(ST.Ping_number);
    idx_r=nanmin(ST.idx_r-nanmax(np)):nanmax(ST.idx_r+nanmax(np));
    idx_r(idx_r<1)=1;
    idx_r(idx_r>numel(trans_obj.Range))=numel(trans_obj.Range);
    idx_ping_st=nanmin(ST.Ping_number):nanmax(ST.Ping_number);
    
    block_size = nanmin(ceil(block_len/numel(idx_r)),numel(idx_ping_st));
    num_ite = ceil(numel(idx_ping_st)/block_size);
    
    for ui=1:num_ite
        idx_ping=idx_ping_st((ui-1)*block_size+1:nanmin(ui*block_size,numel(idx_ping_st)));
        dataMat=-999*ones(numel(idx_r),numel(idx_ping));
        
        [~,np]=trans_obj.get_pulse_Teff(idx_ping);
        
        switch trans_obj.Mode
            case 'CW'
                np=ceil(np/4);
            case 'FM'
                np = ceil(np/8);
        end
        
        idx_targets=find(ismember(ST.Ping_number,idx_ping));
        ping_num=ST.Ping_number(idx_targets);
        
        np_targets=np(1);
        idx_r_targets=ST.idx_r(idx_targets)-idx_r(1)+1;
        
        idx_r_s=idx_r_targets-np_targets();
        idx_r_s(idx_r_s<1)=1;
        idx_r_e=idx_r_targets+np_targets;
        idx_r_e(idx_r_e>numel(idx_r))=numel(idx_r);
        
        for it=1:numel(idx_r_e)
            dataMat(idx_r_s(it):idx_r_e(it),ping_num(it)-idx_ping(1)+1)=ST.TS_comp(idx_targets(it));
        end
        
        trans_obj.Data.replace_sub_data_v2(dataMat,'field','singletarget','idx_r',idx_r,'idx_ping',idx_ping);
    end
end

trans_obj.ST=ST;


end