function lines=nmea_to_lines(nmea_struct,nmea_type)
lines=[];
for it=1:numel(nmea_type)
    idx_NMEA=find(ismember(nmea_struct.type,nmea_type{it}));
    if ~isempty(idx_NMEA)
        [trans_depth,depth_time]=nmea_to_depth_trans(nmea_struct.string,nmea_struct.time,idx_NMEA);
        lines=[lines line_cl('Name',sprintf('TransducerDepth from %s',nmea_type{it}),'Range',trans_depth,'Time',depth_time)];
    end
end
end