function [T,Np]=get_pulse_comp_Teff(trans_obj,varargin)

Np=double(ceil(trans_obj.get_params_value('TeffCompPulseLength',[])./trans_obj.get_params_value('SampleInterval',[])));
T=double(trans_obj.get_params_value('TeffCompPulseLength',[]));

if ~isempty(varargin)
    Np=Np(varargin{1});
    T=T(varargin{1});
end

end