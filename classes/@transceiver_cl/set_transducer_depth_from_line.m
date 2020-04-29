function set_transducer_depth_from_line(trans_obj,line_obj)
trans_obj.TransducerDepth=zeros(size(trans_obj.Time));

if ~isempty(line_obj)
    curr_dist=trans_obj.GPSDataPing.Dist;
    curr_time=trans_obj.GPSDataPing.Time;
    time_out=[];
    r_out=[];
    
    for i=1:numel(line_obj)
        idx_add=~isnan(line_obj(i).Range(:));
        time_out=[time_out line_obj(i).Time(idx_add)];
        r_out=[r_out line_obj(i).Range(idx_add)];
    end
    
    [time_tot,idx_sort]=unique(time_out);
    r_tot=r_out(idx_sort);
    
    if nansum(curr_dist)>0  
        curr_dist_red=resample_data_v2(curr_dist,curr_time,time_tot);
        dist_corr=curr_dist_red-line_obj(1).Dist_diff;
        time_corr=resample_data_v2(time_tot,curr_dist_red,dist_corr);
        range_line=resample_data_v2(r_tot,time_tot,time_corr);
    else
        range_line=r_tot;
        time_corr=time_tot;
    end
    
    idx_nan=isnan(range_line);
    range_line(idx_nan)=[];
    time_corr(idx_nan)=[];
    %     [~,idx_t]=nanmin(abs(time_corr(1)-curr_time(:)'));
    %     idx_tt=idx_t:nanmin(numel(trans_obj.TransducerDepth),numel(range_line));
    
    [dt,idx_t]=nanmin(abs(time_corr(:)-trans_obj.Time(:)'),[],1);
    idx_rem= dt>10*mode(diff(trans_obj.Time));
    range_t=range_line(idx_t);
    range_t(idx_rem)=0;
    trans_obj.TransducerDepth=range_t(:)';
    
end
  
end