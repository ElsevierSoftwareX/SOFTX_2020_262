function [gps_data,attitude_full,time_diff]=nmea_to_attitude_gps_v2(NMEA_string_cell,NMEA_time,idx_NMEA)

curr_gps=0;
curr_dist=0;
curr_att=0;
curr_heading=0;
[nmea,nmea_type]=cellfun(@parseNMEA,NMEA_string_cell(idx_NMEA),'UniformOutput',0);

NMEA_time=NMEA_time(idx_NMEA);

idx_gps=strcmp(nmea_type,'gps');
nmea_gps=nmea(idx_gps);
time_nmea_gps=NMEA_time(idx_gps);
time_diff=0;
try
    seconds_computer=time_nmea_gps*(24*60*60)-floor(time_nmea_gps)*24*60*60;
    seconds_gps=nan(1,numel(nmea_gps));
    for i=1:numel(nmea_gps)
        if ~isempty(nmea_gps{i}.time)
            if numel(nmea_gps{i}.time)==3
                seconds_gps(i)=nansum(double(nmea_gps{i}.time).*[60*60 60 1]);
            end
        end
    end
    
    time_diff=nanmean(seconds_gps-seconds_computer);
    
catch
    disp('Could not compare GPS to computer time');
end

for iiii=1:length(idx_NMEA)
    
    try
        switch nmea_type{iiii}
            case 'gps'
                
                %Because gps messages can sometimes be corrupted
                %with spurious characters it is possible to parse
                %the NMEA message and still end up with invalid
                %lat/long values. The tests below are to ignore
                %such values
                
                if ~isempty(nmea{iiii}.lat) && isreal(nmea{iiii}.lat)       ...
                        && ~isempty(nmea{iiii}.lon) && isreal(nmea{iiii}.lon)       ...
                        && (nmea{iiii}.lat_hem == 'S' || nmea{iiii}.lat_hem == 'N') ...
                        && (nmea{iiii}.lon_hem == 'E' || nmea{iiii}.lon_hem == 'W')
                    
                    curr_gps=curr_gps+1;
                    gps.type{curr_gps}=nmea{iiii}.type(3:end);
                    gps.time(curr_gps) = NMEA_time(iiii);
                    %  set lat/lon signs and store values
                    if (nmea{iiii}.lat_hem == 'S')
                        gps.lat(curr_gps) = -nmea{iiii}.lat;
                    else
                        gps.lat(curr_gps) = nmea{iiii}.lat;
                    end
                    if (nmea{iiii}.lon_hem == 'W')
                        gps.lon(curr_gps) = -nmea{iiii}.lon;
                    else
                        gps.lon(curr_gps) = nmea{iiii}.lon;
                    end
                    
                    
                end
                %             case 'speed'
                %                 vspeed.time(curr_speed) = dgTime;
                %                 vspeed.speed(curr_speed) = nmea{iiii}.sog_knts;
                %                 curr_speed = curr_speed + 1;
            case 'dist'
                if ~isempty(nmea{iiii}.total_cum_dist)
                    curr_dist=curr_dist+1;
                    dist.time(curr_dist) = NMEA_time(iiii);
                    dist.vlog(curr_dist) = nmea{iiii}.total_cum_dist;
                    
                end
            case 'attitude'
                if  ~isempty(nmea{iiii}.heading) && ~isempty(nmea{iiii}.pitch) && ~isempty(nmea{iiii}.roll) && ~isempty(nmea{iiii}.heave) && ~isempty(nmea{iiii}.yaw)
                    curr_att=curr_att+1;
                    attitude.time(curr_att) = NMEA_time(iiii);
                    attitude.heading(curr_att) = nmea{iiii}.heading;
                    attitude.pitch(curr_att) = nmea{iiii}.pitch;
                    attitude.roll(curr_att) = nmea{iiii}.roll;
                    attitude.yaw(curr_att) = nmea{iiii}.yaw;
                    attitude.heave(curr_att) = nmea{iiii}.heave;
                    attitude.type{curr_att}=nmea{iiii}.type;
                end
            case 'heading'
                if ~isempty(nmea{iiii}.heading)
                    curr_heading=curr_heading+1;
                    heading.time(curr_heading) = NMEA_time(iiii);
                    heading.heading(curr_heading) = nmea{iiii}.heading;
                    heading.type{curr_heading}=nmea{iiii}.type;
                end
        end
    catch
        fprintf('Invalid NMEA message: %s\n',NMEA_string_cell{idx_NMEA(iiii)});
    end
end

if curr_gps>0&&isfield(gps,'lat')
    types=unique(gps.type);
    nb_type=cellfun(@(x) nansum(strcmp(x,gps.type)),types);
    [~,id_max]=nanmax(nb_type);
    id_keep=strcmp(types(id_max),gps.type);
    gps_data=gps_data_cl('Lat',gps.lat(id_keep),'Long',gps.lon(id_keep),'Time',gps.time(id_keep),'NMEA',gps.type{id_max});
else
    gps_data=gps_data_cl();
end

if curr_heading>0
    types=unique(heading.type);
    nb_type=cellfun(@(x) nansum(strcmp(x,heading.type)),types);
    [~,id_max]=nanmax(nb_type);
    id_keep=strcmp(types(id_max),heading.type);
    attitude_heading=attitude_nav_cl('Heading',heading.heading(id_keep),'Time',heading.time(id_keep),'NMEA_heading',heading.type{id_max});
elseif numel(gps_data.Lat)>2
    attitude_heading=att_heading_from_gps(gps_data,10);
else
    attitude_heading=attitude_nav_cl.empty();
end

if curr_att>0
    types=unique(attitude.type);
    id_max=find(strcmpi(types,'PASHR'));
    if isempty(id_max)
        nb_type=cellfun(@(x) nansum(strcmp(x,attitude.type)),types);
        [~,id_max]=nanmax(nb_type);
    end
    id_keep=strcmp(types(id_max),attitude.type);
    attitude_full=attitude_nav_cl('Yaw',attitude.yaw(id_keep),'Heading',...
        attitude.heading(id_keep),'Pitch',attitude.pitch(id_keep),'Roll',...
        attitude.roll(id_keep),'Heave',attitude.heave(id_keep),'Time',attitude.time(id_keep),'NMEA_motion',types{id_max},'NMEA_heading','t');
    if all(isnan(attitude_full.Heading))
        if ~isempty(attitude_heading)
            attitude_full.Heading=resample_data_v2(attitude_heading.Heading,attitude_heading.Time,attitude_full.Time,'Type','Angle');
            attitude_full.NMEA_heading=attitude_heading.NMEA_heading;
        end
    end
elseif ~isempty(attitude_heading)
    attitude_full=attitude_heading;
else
    attitude_full=attitude_nav_cl.empty();
end
% figure();plot(attitude_full_2.Time,attitude_full_2.Heading);hold on;
% plot(attitude_full.Time,attitude_full.Heading);
% plot(attitude_full_3.Time,attitude_full_3.Heading);

