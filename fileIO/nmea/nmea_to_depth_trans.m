
function [depth_trans,depth_time]=nmea_to_depth_trans(NMEA_string_cell,NMEA_time,idx_NMEA)

depth_trans=zeros(1,length(idx_NMEA));
depth_time=zeros(1,length(idx_NMEA));
idx_rem=[];
ii=0;
for iiii=idx_NMEA(:)'
    ii=ii+1;
    %for iiii=1:length(NMEA_string_cell)
    curr_message=NMEA_string_cell{iiii};
    curr_message(isspace(curr_message))=' ';
     try
         [nmea,nmea_type]=parseNMEA(curr_message);
   
        switch nmea_type
            case 'depth'
                depth_trans(ii)=abs(nmea.depth);
                depth_time(ii)=NMEA_time(iiii);
            otherwise
                idx_rem=union(idx_rem,ii);
        end       
     catch
          fprintf('Invalid NMEA message: %s\n',curr_message);
          idx_rem=union(idx_rem,ii);
     end   
end

 depth_trans(idx_rem)=[];depth_time(idx_rem)=[];