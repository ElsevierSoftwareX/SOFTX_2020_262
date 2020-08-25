function [ping_new_mat,depth_new_mat,data_new,sc]=apply_line_depth(trans_obj,curr_field,idx_r,idx_beam,idx_ping)

[data_new,sc] = trans_obj.Data.get_subdatamat('idx_r',idx_r,'idx_ping',idx_ping,'idx_beam',idx_beam,'field',curr_field);
depth_new_mat=trans_obj.get_transceiver_depth(idx_r,idx_ping);

ping_new_mat=repmat(idx_ping,size(depth_new_mat,1),1);




