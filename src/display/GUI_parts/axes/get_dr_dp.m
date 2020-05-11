function [dr,dp]=get_dr_dp(ax,nb_samples,nb_pings,echoQuality,echoType)

screensize = getpixelposition(ax);
outputSize=screensize(3:4);

switch echoQuality
    case 'high'
        dqf=2;
    case 'medium'
        dqf=1.5;
    case 'low'
        dqf=1;
    case 'very_low'
        dqf=0.5;
    otherwise
        dqf=1.5;
end

outputSize=round(dqf*outputSize);

switch echoType
    case  'image'
        dr=nanmax(ceil(nb_samples/outputSize(2)),1);
        dp=nanmax(ceil(nb_pings/outputSize(1))-1,1);
    case 'surface'
        dr=nanmax(ceil(nb_samples/outputSize(2)),1);
        dp=nanmax(floor(nb_pings/outputSize(1)),1);
end
