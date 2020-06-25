function cal_struct=get_cal(layer_obj)
freqs=layer_obj.Frequencies;
cal_struct.FREQ=freqs;
cal_struct.CID=deblank(layer_obj.ChannelID);
cal_struct.alpha=nan(1,numel(freqs));
cal_struct.G0=nan(1,numel(freqs));
cal_struct.SACORRECT=nan(1,numel(freqs));
cal_struct.BeamWidthAlongship=nan(1,numel(freqs));
cal_struct.BeamWidthAthwartship=nan(1,numel(freqs));

for i=1:numel(freqs)  
    cal_t=layer_obj.Transceivers(i).get_cal();
    cal_struct.alpha(i)=nanmean(layer_obj.Transceivers(i).get_absorption())*1e3;
    cal_struct.G0(i)=cal_t.G0;
    cal_struct.EQA(i)=cal_t.EQA;
    cal_struct.SACORRECT(i)=cal_t.SACORRECT;
    cal_struct.BeamWidthAthwartship(i)=layer_obj.Transceivers(i).Config.BeamWidthAthwartship;
    cal_struct.BeamWidthAlongship(i)=layer_obj.Transceivers(i).Config.BeamWidthAlongship;
end

end