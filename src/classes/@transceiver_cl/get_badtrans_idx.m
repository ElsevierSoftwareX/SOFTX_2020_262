function idx_bad = get_badtrans_idx(trans_obj,idx_pings)

idx_bad = find(trans_obj.Bottom.Tag(idx_pings)==0);

end