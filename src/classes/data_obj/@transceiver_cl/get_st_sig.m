function st_sig=get_st_sig(trans_obj,field)

st=trans_obj.ST;
if isempty(st)
    st_sig={};
    return;
end

st_sig=cell(1,numel(st.Ping_number));

nb_samples=numel(trans_obj.Data.get_samples);
[~,N]=trans_obj.get_pulse_length;
N_st=N(st.Ping_number);
idx_r_st=st.idx_r-N_st;
idx_r_et=st.idx_r+N_st-1;

for ii=1:numel(st.Ping_number)
    idx_r=idx_r_st(ii):idx_r_et(ii);
    idx_r=idx_r+nansum(idx_r<1);
    idx_r=idx_r-nansum(idx_r>nb_samples);
    st_sig{ii}=trans_obj.Data.get_subdatamat('idx_r',idx_r,'idx_ping',st.Ping_number(ii),'field',field);
end