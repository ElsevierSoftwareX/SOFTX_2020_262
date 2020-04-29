function cal_struct=get_fm_cal(trans_obj,cal_path)


int_meth='linear';
ext_meth=nan;

FreqStart=(trans_obj.get_params_value('FrequencyStart',1));
FreqEnd=(trans_obj.get_params_value('FrequencyEnd',1));
f_nom=(trans_obj.Config.Frequency);
gain=trans_obj.get_current_gain();

eq_beam_angle=trans_obj.Config.EquivalentBeamAngle;

cal_struct.freq_vec=nanmin(FreqStart,FreqEnd):10:nanmax(FreqStart,FreqEnd);
cal_struct.Gf_th=gain+20*log10(cal_struct.freq_vec./f_nom);

cal_struct.eq_beam_angle_f_th=eq_beam_angle+20*log10(f_nom./cal_struct.freq_vec);

cal_struct.BeamWidthAlongship_f_th=trans_obj.Config.BeamWidthAlongship*10.^((f_nom-cal_struct.freq_vec)/f_nom/2.2578);

cal_struct.BeamWidthAthwartship_f_th=trans_obj.Config.BeamWidthAthwartship*10.^((f_nom-cal_struct.freq_vec)/f_nom/2.2578);

cal_struct.Gf_file=nan(size(cal_struct.freq_vec));
cal_struct.eq_beam_angle_f_file=nan(size(cal_struct.freq_vec));
cal_struct.BeamWidthAlongship_f_file=nan(size(cal_struct.freq_vec));
cal_struct.BeamWidthAthwartship_f_file=nan(size(cal_struct.freq_vec));

cal_struct.BeamWidthAlongship_f_fit=nan(size(cal_struct.freq_vec));
cal_struct.BeamWidthAthwartship_f_fit=nan(size(cal_struct.freq_vec));

file_cal=fullfile(cal_path,['Curve_' trans_obj.Config.ChannelID '.mat']);
if ~isfile(file_cal)
    file_cal=fullfile(cal_path,['Curve_' num2str(f_nom,'%.0f') '.mat']);
end

file_cal_eba=fullfile(cal_path,[ 'Curve_EBA_' trans_obj.Config.ChannelID '.mat']);

if ~isfile(file_cal_eba)
    file_cal_eba=fullfile(cal_path,[ 'Curve_EBA_' num2str(f_nom,'%.0f') '.mat']);
end

if ~isempty(trans_obj.Config.Cal_FM)
    
    cal_struct.Gf_file = interp1(trans_obj.Config.Cal_FM.Frequency,trans_obj.Config.Cal_FM.Gain,cal_struct.freq_vec,int_meth,ext_meth);
    
    cal_struct.BeamWidthAlongship_f_file = interp1(trans_obj.Config.Cal_FM.Frequency,trans_obj.Config.Cal_FM.BeamWidthAlongship,cal_struct.freq_vec,int_meth,ext_meth);
    
    cal_struct.BeamWidthAthwartship_f_file = interp1(trans_obj.Config.Cal_FM.Frequency,trans_obj.Config.Cal_FM.BeamWidthAthwartship,cal_struct.freq_vec,int_meth,ext_meth);
    
    cal_struct.eq_beam_angle_f_file=10*log10(2.2578*sind(cal_struct.BeamWidthAlongship_f_file/4+cal_struct.BeamWidthAthwartship_f_file/4).^2);
end


if isfile(file_cal)
    disp_perso([],sprintf('Gain Calibration file for Channel %s found',trans_obj.Config.ChannelID));
    cal_f=load(file_cal);
    cal_struct.Gf = interp1(cal_f.freq_vec,cal_f.Gf,cal_struct.freq_vec,int_meth,ext_meth);    
elseif ~isempty(trans_obj.Config.Cal_FM)
    disp_perso([],sprintf('Gain Calibration for Channel %s using file values',trans_obj.Config.ChannelID));
    cal_struct.Gf = cal_struct.Gf_file;
else
    cal_struct.Gf=cal_struct.Gf_th;
    disp_perso([],sprintf('Gain Calibration for Channel %s using theoritical values',trans_obj.Config.ChannelID));
end


if isfile(file_cal_eba)
    disp_perso([],sprintf('EBA Calibration file for Channel %s found',trans_obj.Config.ChannelID));
    cal_eba_f=load(file_cal_eba);
    
    cal_struct.BeamWidthAlongship_f_fit = interp1(cal_eba_f.freq_vec,cal_eba_f.BeamWidthAlongship_f_fit,cal_struct.freq_vec,int_meth,ext_meth);
    cal_struct.BeamWidthAthwartship_f_fit = interp1(cal_eba_f.freq_vec,cal_eba_f.BeamWidthAthwartship_f_fit,cal_struct.freq_vec,int_meth,ext_meth);
     cal_struct.eq_beam_angle_f=10*log10(2.2578*sind(cal_struct.BeamWidthAthwartship_f_fit/4+cal_struct.BeamWidthAlongship_f_fit/4).^2);
elseif ~isempty(trans_obj.Config.Cal_FM)
    disp_perso([],sprintf('EBA Calibration for Channel %s using file values',trans_obj.Config.ChannelID));
    cal_struct.BeamWidthAlongship_f_fit=cal_struct.BeamWidthAlongship_f_file;
    cal_struct.BeamWidthAthwartship_f_fit=cal_struct.BeamWidthAthwartship_f_file;    
    cal_struct.eq_beam_angle_f=10*log10(2.2578*sind(cal_struct.BeamWidthAthwartship_f_fit/4+cal_struct.BeamWidthAlongship_f_fit/4).^2);
else
    cal_struct.BeamWidthAlongship_f_fit=cal_struct.BeamWidthAlongship_f_th;
    cal_struct.BeamWidthAthwartship_f_fit=cal_struct.BeamWidthAthwartship_f_th;
    cal_struct.eq_beam_angle_f=cal_struct.eq_beam_angle_f_th;
    %disp_perso([],sprintf('EBA Calibration for Channel %s using theoritical values',trans_obj.Config.ChannelID));
    
end
 

