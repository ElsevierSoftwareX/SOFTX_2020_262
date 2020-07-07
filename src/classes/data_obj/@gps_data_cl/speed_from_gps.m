function [speed,time_s]=speed_from_gps(gps_data_obj,dt)
dist=gps_data_obj.Dist;
time=gps_data_obj.Time(1:end);
n=ceil(dt/(nanmean(diff(time))*24*60*60));
speed=gradient(dist(1:n:end)/1852)./gradient(time(1:n:end)*24*60*60/3600);
time_s=time(1:n:end);