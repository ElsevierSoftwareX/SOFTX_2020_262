function remove_transceiver(layer_obj,varargin)

p = inputParser;

addRequired(p,'layer_obj',@(obj) isa(obj,'layer_cl'));

addParameter(p,'load_bar_comp',[]);
addParameter(p,'Channels',{},@iscell);


parse(p,layer_obj,varargin{:});

channels_open=layer_obj.ChannelID;
channels_to_rem=p.Results.Channels(ismember(p.Results.Channels,channels_open));

idx_rem=find(ismember(channels_open,channels_to_rem));

if isempty(idx_rem)
    return;
else
    layer_obj.rm_memaps(idx_rem);
    layer_obj.Frequencies(idx_rem)=[];
    layer_obj.ChannelID(idx_rem)=[];
    layer_obj.Transceivers(idx_rem)=[];
end

end