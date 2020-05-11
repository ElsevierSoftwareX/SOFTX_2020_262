function [LatLim_out,LongLim_out]=ext_lat_lon_lim_v2(LatLim_in,LongLim_in,fext)

 lat_diff=abs(diff(LatLim_in));
 lon_diff=abs(diff(LongLim_in));
 
 LatLim_out=LatLim_in+fext*[-lat_diff lat_diff];
 LongLim_out=LongLim_in+fext*[-lon_diff lon_diff];
 
 LatLim_out(LatLim_out>90)=90;
 LatLim_out(LatLim_out<-90)=-90;
  
   LongLim_out(LongLim_out>360)=360;
  LongLim_out(LongLim_out<0)=0;
 
end