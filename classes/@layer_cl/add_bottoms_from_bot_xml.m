function xml_parsed = add_bottoms_from_bot_xml(layer_obj,varargin)

% input parser
p = inputParser;
addRequired(p,'layer_obj',@(obj) isa(obj,'layer_cl'));
addParameter(p,'Frequencies',[]);
addParameter(p,'Channels',{});
addParameter(p,'Version',-1);
parse(p,layer_obj,varargin{:});

new_bottom = cell(1,length(layer_obj.Transceivers));

[path_xml,~,bot_file_str] = layer_obj.create_files_str();

xml_parsed = ones(1,length(bot_file_str));
init_bot = ones(1,length(layer_obj.Transceivers));

for ix = 1:length(bot_file_str)
    
    % retrieve XML filename and move on if it does not exist
    xml_file = fullfile(path_xml{ix},bot_file_str{ix});
    if exist(xml_file,'file')==0
        fprintf('No bottom xml file for %s.\n',layer_obj.Filename{ix});
        xml_parsed(ix) = 0;
        continue;
    end
    
    % parse XML file and move on if it cannot be read
    [bottom_xml_tot,bot_fmt_ver] = parse_bottom_xml(xml_file);
    if isempty(bottom_xml_tot)
        fprintf('Could not parse bottom xml file for %s.\n',layer_obj.Filename{ix});
        xml_parsed(ix) = 0;
        continue;
    end
    
    % if we're here, we have read the bottom XML file. Working per channel
    % from now on
    for itrans = 1:length(bottom_xml_tot)
        
        % get corresponding channel
        bottom_xml = bottom_xml_tot{itrans};
        [trans_obj,idx_freq] = layer_obj.get_trans(bottom_xml.Infos);
        
        if isempty(trans_obj)
            %fprintf('Bottom XML file was read but could not load data for frequency %.0f kHz.\n',bottom_xml.Infos.Freq/1e3);
            continue;
        end
        
        if ~strcmp(deblank(trans_obj.Config.ChannelID),bottom_xml.Infos.ChannelID)
            fprintf('This bottom have been written for a different channel: %s.\n',deblank(bottom_xml.Infos.ChannelID));
        end
        
        bot_xml = bottom_xml.Bottom;
        
        if init_bot(idx_freq)==1
            init_bot(idx_freq)=0;
            % initialize bottom object
            new_bottom{idx_freq} = bottom_cl(...
                'Sample_idx',nan(1,numel(layer_obj.Transceivers(idx_freq).Data.FileId)),...
                'Origin',sprintf('XML_v%s',bot_fmt_ver),...
                'Version',p.Results.Version);
        end
        
        switch bot_fmt_ver
            case '0.1'
                print_errors_and_warnings([],'warning','This bottom definition is imported from an old bottom file, if the soundspeed has been modified it might not be in the right place!');
                time = bot_xml.Time;
                range = bot_xml.Range;
                tag = bot_xml.Tag;
                
                if time(1)<=trans_obj.Time(1)
                    [~,idx_ping_start] = nanmin(abs(trans_obj.Time(1)-time(1)));
                    idx_start_file = 1;
                else
                    idx_ping_start = 1;
                    [~,idx_start_file] = nanmin(abs(trans_obj.Time-time(1)));
                end
                
                if time(end)>=trans_obj.Time(end)
                    [~,idx_ping_end] = nanmin(abs(trans_obj.Time(end)-time));
                    idx_end_file = length(trans_obj.Time);
                else
                    idx_ping_end = length(time);
                    [~,idx_end_file] = nanmin(abs(trans_obj.Time-time(end)));
                end
                
                if  time(end)<=trans_obj.Time(1)||time(1)>=trans_obj.Time(end)
                    warning('No common time between file an bottom file');
                    continue;
                end
                
                depth_resampled = resample_data_v2(range(idx_ping_start:idx_ping_end),time(idx_ping_start:idx_ping_end),trans_obj.Time(idx_start_file:idx_end_file),'Opt','Nearest');
                sample_idx = resample_data_v2((1:length(trans_obj.get_transceiver_range())),trans_obj.get_transceiver_range(),depth_resampled,'Opt','Nearest');
                tag_resampled = resample_data_v2(tag(idx_ping_start:idx_ping_end),time(idx_ping_start:idx_ping_end),trans_obj.Time(idx_start_file:idx_end_file),'Opt','Nearest');
                
                sample_idx(sample_idx<=1)=nan;
                nb_val=nanmin(numel(sample_idx),numel(idx_start_file:idx_end_file));
                new_bottom{idx_freq}.Sample_idx(idx_start_file:idx_end_file) = sample_idx(1:nb_val);
                new_bottom{idx_freq}.Tag(idx_start_file:idx_end_file) = tag_resampled(1:nb_val);
                
            case '0.2'
                pings   = bot_xml.Ping;
                samples = bot_xml.Sample;
                tag     = bot_xml.Tag;
                
                samples(samples<=1) = nan;
                nb_val=nanmin(numel(samples),numel(new_bottom{idx_freq}.Sample_idx));
                iping_ori = find(layer_obj.Transceivers(idx_freq).Data.FileId==ix,1);
                if ~isempty(pings)
                    new_bottom{idx_freq}.Sample_idx(pings+iping_ori-1) = samples(1:nb_val);
                    new_bottom{idx_freq}.Tag(pings+iping_ori-1)        = tag(1:nb_val);
                end
                % this XML file has an older format version that did not
                % have E1 and E2. That's ok, the bottom object was created
                % with empty E1 and E2 and they will be given default
                % values when attached to the trans object.
                
            case '0.3'
                pings   = bot_xml.Ping;
                samples = bot_xml.Sample;
                tag     = bot_xml.Tag;
                E1      = bot_xml.E1;
                E2      = bot_xml.E2;
                
                samples(samples<=1) = nan;
               nb_val=nanmin(numel(samples),numel(new_bottom{idx_freq}.Sample_idx));
                if ~isempty(pings)
                    iping_ori = find(layer_obj.Transceivers(idx_freq).Data.FileId==ix,1);
                    
                    new_bottom{idx_freq}.Sample_idx(pings+iping_ori-1) = samples(1:nb_val);
                    new_bottom{idx_freq}.Tag(pings+iping_ori-1)        = tag(1:nb_val);
                    new_bottom{idx_freq}.E1(pings+iping_ori-1)         = E1(1:nb_val);
                    new_bottom{idx_freq}.E2(pings+iping_ori-1)         = E2(1:nb_val);
                end
                
        end
    end
end

% add bottom objects to each transceiver (channel) object
for idx_freq = 1:length(layer_obj.Transceivers)
    
    trans_obj = layer_obj.Transceivers(idx_freq);
    
    if isempty(new_bottom{idx_freq})
        continue;
    end
    
    trans_obj.Bottom = new_bottom{idx_freq};
    
end

end



