function obj_out=resample_attitude_nav_data(obj,time)
       

if ~isempty(obj.Roll)
    heading_pings=resample_data_v2(obj.Heading,obj.Time,time,'Type','Angle');
    heading_pings(heading_pings<0)=heading_pings(heading_pings<0)+360;
    pitch_pings=resample_data_v2(obj.Pitch,obj.Time,time,'Type','Angle');
    roll_pings=resample_data_v2(obj.Roll,obj.Time,time,'Type','Angle');
    heave_pings=resample_data_v2(obj.Heave,obj.Time,time,'Type','Angle');
    yaw_pings=resample_data_v2(obj.Yaw,obj.Time,time,'Type','Angle');
    obj_out=attitude_nav_cl('Heading',heading_pings,'Pitch',pitch_pings,'Roll',roll_pings,'Heave',heave_pings,'Time',time,'Yaw',yaw_pings);
    
elseif ~isempty(obj.Heading)    
    heading_pings=resample_data_v2(obj.Heading,obj.Time,time,'Type','Angle');
    obj_out=attitude_nav_cl('Heading',heading_pings,'Time',time);
else
    obj_out=attitude_nav_cl('Time',time);
end
        
obj_out.NMEA_motion=obj.NMEA_motion;
obj_out.NMEA_heading=obj.NMEA_heading;
end