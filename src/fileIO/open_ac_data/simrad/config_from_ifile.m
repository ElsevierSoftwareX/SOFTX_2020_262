function [config_obj,params_obj]=config_from_ifile(ifile,nb_pings)
config_obj=config_cl();
params_obj=params_cl(nb_pings);


ifileInfo=parse_ifile(ifile);

config_obj.TransceiverName='CREST';
config_obj.AngleSensitivityAlongship=ifileInfo.angle_factor_alongship;
config_obj.AngleSensitivityAthwartship=ifileInfo.angle_factor_alongship;
config_obj.BeamType='singlebeam';
config_obj.BeamWidthAlongship=7;
config_obj.BeamWidthAthwartship=7;
config_obj.Frequency=38000;
config_obj.FrequencyMaximum=38000;
config_obj.FrequencyMinimum=38000;
config_obj.TransducerSerialNumber=ifileInfo.transducer_id;
config_obj.ChannelID=[ifileInfo.sounder_type '_' ifileInfo.transducer_id];
config_obj.Gain=ifileInfo.G0;
config_obj.SaCorrection=ifileInfo.SACORRECT;
config_obj.EquivalentBeamAngle=-20.60;

params_obj.FrequencyEnd(:)=38000;
params_obj.FrequencyStart(:)=38000;
params_obj.Frequency(:)=38000;
params_obj.TransmitPower(:)=2000;

if isnan(ifileInfo.sound_speed)
    soundspeed=1500;
else
    soundspeed=ifileInfo.sound_speed;
end

if isnan(ifileInfo.transmit_pulse_length)
    params_obj.PulseLength(:)=4/ifileInfo.depth_factor/soundspeed*2;
else
    params_obj.PulseLength(:)=ifileInfo.transmit_pulse_length; 
end
params_obj.TeffPulseLength=params_obj.PulseLength;
params_obj.TeffCompPulseLength=params_obj.PulseLength;
params_obj.SampleInterval(:)=2/ifileInfo.depth_factor/soundspeed;
params_obj.Absorption(:)=ifileInfo.absorption_coefficient/1000;

end