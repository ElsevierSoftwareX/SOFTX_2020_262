function load_ek_bot(layer_obj,varargin)
p = inputParser;

addRequired(p,'layer_obj',@(obj) isa(obj,'layer_cl'));
addParameter(p,'Frequencies',[]);
addParameter(p,'Channels',{});
parse(p,layer_obj,varargin{:});

Filenames=layer_obj.Filename;
Bottom_sim.depth=[];
Bottom_sim.time=[];
frequencies=[];
try
    for ui=1:numel(Filenames)
        [p_tmp,f_tmp,~]=fileparts(Filenames{ui});
        Filename_bot=fullfile(p_tmp,[f_tmp '.bot']);
        
        if isfile(Filename_bot)
            [Bottom_sim_temp, frequencies_temp] = readEKBotSimple(Filename_bot);
        else
            continue;
        end
        
        if isempty(frequencies)
            Bottom_sim.depth=Bottom_sim_temp.depth;
            Bottom_sim.time=Bottom_sim_temp.time;
            frequencies=frequencies_temp;
        else
            if all(frequencies==frequencies_temp)
                Bottom_sim.time=[Bottom_sim.time Bottom_sim_temp.time];
                Bottom_sim.depth=[Bottom_sim.depth Bottom_sim_temp.depth];
            end
        end
        
    end
    
    
    for itrans=1:length(layer_obj.Transceivers)
        if (~isempty(p.Results.Frequencies)&&~any(layer_obj.Frequencies(itrans)==p.Results.Frequencies))||...
                (~isempty(p.Results.Channels)&&~any(strcmpi(layer_obj.ChannelID{itrans},p.Results.Channels)))
            continue;
        end
        idx_bot=find(layer_obj.Frequencies(itrans)==frequencies);
        if ~isempty(idx_bot)
            curr_range=layer_obj.Transceivers(itrans).get_transceiver_range();
            depth_resampled=resample_data_v2(Bottom_sim.depth(idx_bot,:),Bottom_sim.time,layer_obj.Transceivers(itrans).Time);
            depth_resampled=depth_resampled-layer_obj.Transceivers(itrans).TransducerDepth;
            sample_idx=resample_data_v2(1:length(curr_range),curr_range,depth_resampled,'Opt','Nearest');
            sample_idx(sample_idx<1)=1;
            sample_idx(sample_idx==1)=nan;
            layer_obj.Transceivers(itrans).Bottom = bottom_cl('Origin','Simrad','Sample_idx',sample_idx);
        end
    end
    
catch err
    print_errors_and_warnings([],'error',err);
end