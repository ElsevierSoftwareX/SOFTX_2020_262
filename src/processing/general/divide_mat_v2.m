function [data_cell,idx_r_cell,idx_beam_cell,idx_ping_cell]=divide_mat_v2(data,nb_samples,nb_beams,nb_pings,idx_r,idx_beam,idx_ping)

data_cell=cell(1,length(nb_samples));
idx_ping_cell=cell(1,length(nb_samples));
idx_r_cell=cell(1,length(nb_samples));
idx_beam_cell = cell(1,length(nb_samples));

if isempty(idx_ping)
    idx_ping=1:nansum(nb_pings);
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
    
    if isempty(idx_beam)
        idx_beam_c=(1:nb_beams(ip))';
    else
        idx_beam_c=idx_beam;
    end
    
    [~,idx_ping_cell{ip},idx_ping_tmp]=intersect(ipings,idx_ping);
    [~,idx_r_cell{ip},idx_r_tmp]=intersect((1:nb_samples(ip))',idx_r_c);
    [~,idx_beam_cell{ip},idx_beam_tmp]=intersect((1:nb_beams(ip))',idx_beam_c);
    
    if numel(size(data))==3
        data_cell{ip}=data(idx_r_tmp,idx_beam_tmp,idx_ping_tmp);
    else
        data_cell{ip}=data(idx_r_tmp,idx_ping_tmp);
    end
    
end
    

end