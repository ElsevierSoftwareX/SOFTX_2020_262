function notch_filter_layer(layer_obj,varargin)


p = inputParser;

addRequired(p,'layer_obj',@(obj) isa(obj,'layer_cl'));
addParameter(p,'load_bar_comp',[]);
addParameter(p,'block_len',get_block_len(10,'cpu'),@(x) x>0);

parse(p,layer_obj,varargin{:});

for ifreq=1:numel(layer_obj.Frequencies)
    layer_obj.Transceivers(ifreq).notch_filter_transceiver(layer_obj.EnvData,'bands_to_notch',layer_obj.NotchFilter,'load_bar_comp',p.Results.load_bar_comp,'block_len',p.Results.block_len);
end

