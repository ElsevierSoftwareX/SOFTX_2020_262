function idx_bad = get_badtrans_idx(trans_obj,idx_ping)

idx_bad = find(trans_obj.Bottom.Tag(idx_ping)==0);

end