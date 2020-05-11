function [data_cell,idx_r_cell,idx_pings_cell]=divide_mat_v2(data,nb_samples,nb_pings,idx_r,idx_pings)

data_cell=cell(1,length(nb_samples));
idx_pings_cell=cell(1,length(nb_samples));
idx_r_cell=cell(1,length(nb_samples));

if isempty(idx_pings)
    idx_pings=1:nansum(nb_pings);
end

for ip=1:length(nb_pings)
    if ip==1
        ipings=1:nb_pings(1);
    else
        ping_start=nansum(nb_pings(1:ip-1))+1;
        ping_end=nansum(nb_pings(1:ip));
        ipings=ping_start:ping_end;
    end
    if isempty(idx_r)
        idx_r_c=(1:nb_samples(ip))';
    else
        idx_r_c=idx_r;
    end
    [~,idx_pings_cell{ip},idx_ping_tmp]=intersect(ipings,idx_pings);
    [~,idx_r_cell{ip},idx_r_tmp]=intersect((1:nb_samples(ip))',idx_r_c);
    
    data_cell{ip}=data(idx_r_tmp,idx_ping_tmp);
    
end
    

end