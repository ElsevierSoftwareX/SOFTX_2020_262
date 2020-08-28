function [cal_struct,ori_used]=get_fm_cal(trans_obj,varargin)

p = inputParser;

addRequired(p,'trans_obj',@(x) isa(x,'transceiver_cl'));
addParameter(p,'cal_path','',@ischar);
addParameter(p,'origin','xml',@(x) ismember(x,{'xml','file','th'}));
addParameter(p,'verbose',true,@islogical);
addParameter(p,'f_res',10,@(x) x>0);


parse(p,trans_obj,varargin{:});

int_meth='linear';
ext_meth=nan;

FrequencyMinimum=trans_obj.Config.FrequencyMinimum;
FrequencyMaximum=trans_obj.Config.FrequencyMaximum;
eq_beam_angle=trans_obj.Config.EquivalentBeamAngle;
f_nom=trans_obj.Config.Frequency;
gain=trans_obj.get_current_gain();

ori = {'xml','file','th'};
ori_bool = false(size(ori));


%%%%%%%%%%%%Frequency vector (50Hz resolution)%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cal_struct.Frequency=nanmin(FrequencyMinimum,FrequencyMaximum):p.Results.f_res:nanmax(FrequencyMinimum,FrequencyMaximum);

%%%%%%%%%%%%%%%%Theoritical values%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cal_struct.Gain_th=gain+20*log10(cal_struct.Frequency./f_nom);
%cal_struct.Gain_th=gain+10*log10(cal_struct.Frequency./f_nom);
cal_struct.eq_beam_angle_th=eq_beam_angle+20*log10(f_nom./cal_struct.Frequency);
cal_struct.BeamWidthAlongship_th=asind(sind(trans_obj.Config.BeamWidthAlongship)*f_nom./cal_struct.Frequency);
cal_struct.BeamWidthAthwartship_th=asind(sind(trans_obj.Config.BeamWidthAthwartship)*f_nom./cal_struct.Frequency);
%cal_struct.BeamWidthAthwartship_th=trans_obj.Config.BeamWidthAthwartship*10.^((f_nom-cal_struct.Frequency)/f_nom/2.578);
ori_bool(strcmpi(ori,'th')) = true;

%%%%%%%%%%%%%%%%Raw File values%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cal_struct.Gain_file=nan(size(cal_struct.Frequency));
cal_struct.BeamWidthAlongship_file=nan(size(cal_struct.Frequency));
cal_struct.BeamWidthAthwartship_file=nan(size(cal_struct.Frequency));
cal_struct.eq_beam_angle_file=nan(size(cal_struct.Frequency));

if ~isempty(trans_obj.Config.Cal_FM)
    cal_struct.Gain_file = interp1(trans_obj.Config.Cal_FM.Frequency,trans_obj.Config.Cal_FM.Gain,cal_struct.Frequency,int_meth,ext_meth);
    cal_struct.BeamWidthAlongship_file = interp1(trans_obj.Config.Cal_FM.Frequency,trans_obj.Config.Cal_FM.BeamWidthAlongship,cal_struct.Frequency,int_meth,ext_meth);
    cal_struct.BeamWidthAthwartship_file = interp1(trans_obj.Config.Cal_FM.Frequency,trans_obj.Config.Cal_FM.BeamWidthAthwartship,cal_struct.Frequency,int_meth,ext_meth);
    ori_bool(strcmpi(ori,'file')) = true;
end

%%%%%%%%%%%%%%%%XML File values%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cal_struct.Gain_xml=nan(size(cal_struct.Frequency));
cal_struct.BeamWidthAlongship_xml=nan(size(cal_struct.Frequency));
cal_struct.BeamWidthAthwartship_xml=nan(size(cal_struct.Frequency));
cal_struct.eq_beam_angle_file=nan(size(cal_struct.Frequency));

%%%%%%%%%%%%%%%%%%%Read XML calibration file if available%%%%%%%%%%%%%%%%%%
file_cal=fullfile(p.Results.cal_path,generate_valid_filename(['Calibration_FM_' trans_obj.Config.ChannelID '.xml']));
if ~isfile(file_cal)
    file_cal=fullfile(p.Results.cal_path,generate_valid_filename(['Calibration_FM_' num2str(f_nom,'%.0f') '.xml']));
end

if isfile(file_cal)
    cal_xml = parse_simrad_xml_calibration_file(file_cal);
    cal_struct.Gain_xml = interp1(cal_xml.Frequency,cal_xml.Gain,cal_struct.Frequency,int_meth,ext_meth);
    cal_struct.BeamWidthAlongship_xml = interp1(cal_xml.Frequency,cal_xml.BeamWidthAlongship,cal_struct.Frequency,int_meth,ext_meth);
    cal_struct.BeamWidthAthwartship_xml = interp1(cal_xml.Frequency,cal_xml.BeamWidthAthwartship,cal_struct.Frequency,int_meth,ext_meth);
    ori_bool(strcmpi(ori,'xml')) = true;
end

%%%%%%%%%%%%%%%%Values to be used File%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cal_struct.Gain=nan(size(cal_struct.Frequency));
cal_struct.eq_beam_angle=nan(size(cal_struct.Frequency));
cal_struct.BeamWidthAlongship=nan(size(cal_struct.Frequency));
cal_struct.BeamWidthAthwartship=nan(size(cal_struct.Frequency));
cal_struct.AngleOffsetAlongship = zeros(size(cal_struct.Frequency));
cal_struct.AngleOffsetAthwartship = zeros(size(cal_struct.Frequency));

%%%%%%%%%%%%%%%%%%%Populate values to be used%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

idx_to_use = find(strcmpi(p.Results.origin ,'xml'));
if ~ori_bool(idx_to_use)
    idx_to_use = find(ori_bool,1);
end

ori_used = ori{idx_to_use};
if p.Results.verbose
    switch ori_used
        case 'xml'
            disp_perso([],sprintf('Gain Calibration for Channel %s using XML file values',trans_obj.Config.ChannelID));
        case 'file'
            disp_perso([],sprintf('Gain Calibration for Channel %s using embedded RAW file values',trans_obj.Config.ChannelID));
        case 'th'
            disp_perso([],sprintf('Gain Calibration for Channel %s using theoritical values',trans_obj.Config.ChannelID));
    end
end
fm_fields = get_cal_fm_fields();

for ui = 1:numel(fm_fields)
    if isfield(cal_struct,sprintf('%s_%s',fm_fields{ui},ori_used))
        cal_struct.(fm_fields{ui}) = cal_struct.(sprintf('%s_%s',fm_fields{ui},ori_used));
    end
end

%%%%%%%%%Estimate resulting EBA%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cal_struct.eq_beam_angle=estimate_eba(cal_struct.BeamWidthAthwartship,cal_struct.BeamWidthAlongship);

for ui = 1:numel(ori)
    cal_struct.(sprintf('eq_beam_angle_%s',ori{ui})) = estimate_eba(cal_struct.(sprintf('BeamWidthAthwartship_%s',ori{ui})),cal_struct.(sprintf('BeamWidthAlongship_%s',ori{ui})));
end

end

function eba = estimate_eba(bw_at,bw_al)
eba = 10*log10(2.578*sind(bw_at/4+bw_al/4).^2);
end


