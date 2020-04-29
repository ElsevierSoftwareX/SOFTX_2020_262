function [ping_new_mat,depth_new_mat,data_new,sc]=apply_line_depth(trans_obj,curr_field,idx_r,idx_pings)

[data_new,sc] = trans_obj.Data.get_subdatamat(idx_r,idx_pings,'field',curr_field);
depth_new_mat=trans_obj.get_transceiver_depth(idx_r,idx_pings);
ping_new_mat=repmat(idx_pings,size(depth_new_mat,1),1);




