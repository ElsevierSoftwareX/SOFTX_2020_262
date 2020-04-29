function add_algo(layer_obj,algo_obj,varargin)

p = inputParser;

addRequired(p,'layer_obj',@(obj) isa(obj,'layer_cl'));
addRequired(p,'algo_obj',@(obj) isempty(algo_obj)||isa(algo_obj,'algo_cl'));
addParameter(p,'idx_chan',1:numel(layer_obj.ChannelID),@isnumeric);
addParameter(p,'reset_range',false,@islogical);
parse(p,layer_obj,algo_obj,varargin{:});


for ial=1:numel(algo_obj)
    switch algo_obj(ial).Name
        case 'Classification'
            nb_algos=length(layer_obj.Algo);
            idx_al=find(strcmpi(algo_obj(ial).Name,{layer_obj.Algo(:).Name}));
            
            if ~isempty(idx_al)
                layer_obj.Algo(idx_al)=copy_algo(algo_obj(ial));
            else
                layer_obj.Algo(nb_algos+1)=copy_algo(algo_obj(ial));
            end
            
        otherwise
            for id=1:numel(p.Results.idx_chan)
                layer_obj.Transceivers(p.Results.idx_chan(id)).add_algo(algo_obj(ial),'reset_range',p.Results.reset_range)
            end
    end
end