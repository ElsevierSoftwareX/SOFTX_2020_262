function [cal_struct,used]=get_fm_cal(trans_obj,cal_path)

int_meth='linear';
ext_meth=nan;

FreqStart=(trans_obj.get_params_value('FrequencyStart',1));
FreqEnd=(trans_obj.get_params_value('FrequencyEnd',1));
f_nom=(trans_obj.Config.Frequency);
gain=trans_obj.get_current_gain();
eq_beam_angle=trans_obj.Config.EquivalentBeamAngle;

%%%%%%%%%%%%Frequency vector (10Hz resolution)%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cal_struct.Frequency=nanmin(FreqStart,FreqEnd):10:nanmax(FreqStart,FreqEnd);

%%%%%%%%%%%%%%%%Theoritical values%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cal_struct.Gain_th=gain+20*log10(cal_struct.Frequency./f_nom);
cal_struct.eq_beam_angle_th=eq_beam_angle+20*log10(f_nom./cal_struct.Frequency);
cal_struct.BeamWidthAlongship_th=trans_obj.Config.BeamWidthAlongship*10.^((f_nom-cal_struct.Frequency)/f_nom/2.2578);
cal_struct.BeamWidthAthwartship_th=trans_obj.Config.BeamWidthAthwartship*10.^((f_nom-cal_struct.Frequency)/f_nom/2.2578);

%%%%%%%%%%%%%%%%Raw File values%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cal_struct.Gain_file=nan(size(cal_struct.Frequency));
cal_struct.BeamWidthAlongship_file=nan(size(cal_struct.Frequency));
cal_struct.BeamWidthAthwartship_file=nan(size(cal_struct.Frequency));
cal_struct.eq_beam_angle_file=nan(size(cal_struct.Frequency));

if ~isempty(trans_obj.Config.Cal_FM)    
    cal_struct.Gain_file = interp1(trans_obj.Config.Cal_FM.Frequency,trans_obj.Config.Cal_FM.Gain,cal_struct.Frequency,int_meth,ext_meth);    
    cal_struct.BeamWidthAlongship_file = interp1(trans_obj.Config.Cal_FM.Frequency,trans_obj.Config.Cal_FM.BeamWidthAlongship,cal_struct.Frequency,int_meth,ext_meth);    
    cal_struct.BeamWidthAthwartship_file = interp1(trans_obj.Config.Cal_FM.Frequency,trans_obj.Config.Cal_FM.BeamWidthAthwartship,cal_struct.Frequency,int_meth,ext_meth);    
    cal_struct.eq_beam_angle_file=10*log10(2.2578*sind(cal_struct.BeamWidthAlongship_file/4+cal_struct.BeamWidthAthwartship_file/4).^2);
end

%%%%%%%%%%%%%%%%Values to be used File%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cal_struct.Gain=nan(size(cal_struct.Frequency));
cal_struct.eq_beam_angle=nan(size(cal_struct.Frequency));
cal_struct.BeamWidthAlongship=nan(size(cal_struct.Frequency));
cal_struct.BeamWidthAthwartship=nan(size(cal_struct.Frequency));
cal_struct.AngleOffsetAlongship = zeros(size(cal_struct.Frequency));
cal_struct.AngleOffsetAthwartship = zeros(size(cal_struct.Frequency));


%%%%%%%%%%%%%%%%%%%Read XML calibration file if available%%%%%%%%%%%%%%%%%%
file_cal=fullfile(cal_path,generate_valid_filename(['Calibration_FM_' trans_obj.Config.ChannelID '.xml']));
if ~isfile(file_cal)
    file_cal=fullfile(cal_path,generate_valid_filename(['Calibration_FM_' num2str(f_nom,'%.0f') '.xml']));
end

%%%%%%%%%%%%%%%%%%%Populate values to be used%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isfile(file_cal)
    disp_perso([],sprintf('Gain Calibration file for Channel %s found',trans_obj.Config.ChannelID));
    used = 'XML file';
    cal_f = parse_simrad_xml_calibration_file(file_cal);
    
    cal_struct.Gain = interp1(cal_f.Frequency,cal_f.Gain,cal_struct.Frequency,int_meth,ext_meth);
    cal_struct.BeamWidthAlongship = interp1(cal_f.Frequency,cal_f.BeamWidthAlongship,cal_struct.Frequency,int_meth,ext_meth);
    cal_struct.BeamWidthAthwartship = interp1(cal_f.Frequency,cal_f.BeamWidthAthwartship,cal_struct.Frequency,int_meth,ext_meth);
    cal_struct.eq_beam_angle=10*log10(2.2578*sind(cal_struct.BeamWidthAthwartship/4+cal_struct.BeamWidthAlongship/4).^2);
elseif ~isempty(trans_obj.Config.Cal_FM)
    disp_perso([],sprintf('Gain Calibration for Channel %s using file values',trans_obj.Config.ChannelID));
    used = 'Raw file values';
    cal_struct.Gain = cal_struct.Gain_file;
    cal_struct.BeamWidthAlongship=cal_struct.BeamWidthAlongship_file;
    cal_struct.BeamWidthAthwartship=cal_struct.BeamWidthAthwartship_file;
    cal_struct.eq_beam_angle=10*log10(2.2578*sind(cal_struct.BeamWidthAthwartship/4+cal_struct.BeamWidthAlongship/4).^2);
else
    used = 'Theoritical';
    cal_struct.Gain=cal_struct.Gain_th;
    disp_perso([],sprintf('Gain Calibration for Channel %s using theoritical values',trans_obj.Config.ChannelID));
    cal_struct.BeamWidthAlongship=cal_struct.BeamWidthAlongship_th;
    cal_struct.BeamWidthAthwartship=cal_struct.BeamWidthAthwartship_th;
    cal_struct.eq_beam_angle=cal_struct.eq_beam_angle_th;
end



