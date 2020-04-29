function add_transceiver(layer_obj,varargin)

p = inputParser;

addRequired(p,'layer_obj',@(obj) isa(obj,'layer_cl'));

addParameter(p,'load_bar_comp',[]);
addParameter(p,'Channels',{},@iscell);


parse(p,layer_obj,varargin{:});

filenames=layer_obj.Filename;
channels_open=layer_obj.ChannelID;

channels_to_add=p.Results.Channels(~ismember(p.Results.Channels,channels_open));

if isempty(channels_to_add)
    return;
end

ftype_cell = cellfun(@get_ftype,filenames,'un',0);

if numel(unique(ftype_cell))>  1
    warning('This layer is weird, and compose of data coming from multiple filetype. Cannot add channels to it');
    return;
end

mem_path=fileparts(layer_obj.Transceivers(1).Data.MemapName{1});

[layers,~] = open_file_standalone(filenames,ftype_cell{1},'Channels',channels_to_add,'load_bar_comp',p.Results.load_bar_comp,'PathToMemmap',mem_path);
 if isempty(layers)
     return;
 end


layers_out=rearrange_layers(layers,-1); 

if numel(layers_out)>1
      warning('This layer is weird. Cannot add channels to it');
      layers_out.delete_layers({});
    return;
end
layers_out.load_bot_regs('Channels',channels_to_add);

for ilay=1:numel(layers_out)
    layers_out(ilay).layer_computeSpSv('new_soundspeed',layer_obj.EnvData.SoundSpeed);
end

layer_obj.add_trans(layers_out.Transceivers);


end