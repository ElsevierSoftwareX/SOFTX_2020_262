function  Options = get_options_node(xml_node)
Options = get_node_att(xml_node);

if isfield(Options,'FrequenciesToLoad')
    if ischar(Options.FrequenciesToLoad)
        Options.FrequenciesToLoad = str2double(strsplit(Options.FrequenciesToLoad,';'));
        if isnan(Options.FrequenciesToLoad)
            Options.FrequenciesToLoad = Options.Frequency;
        end
    end
    if isfield(Options,'Absorption')
        abs_ori = Options.Absorption;
        Options.Absorption = nan(1,length(Options.FrequenciesToLoad));
        if ischar(abs_ori)
            abs_temp = str2double(strsplit(abs_ori,';'));
            if length(abs_temp) == length(Options.FrequenciesToLoad)
                Options.Absorption = abs_temp;
            end
        else
            Options.Absorption=abs_ori;
        end
    end
end

end