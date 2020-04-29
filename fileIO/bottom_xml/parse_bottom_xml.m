function [bottom_xml,bot_fmt_ver] = parse_bottom_xml(xml_file)

xml_struct = parseXML(xml_file);

if ~strcmpi(xml_struct.Name,'bottom_file')
    warning('XML file not describing a bottom');
    bottom_xml = [];
    return;
end

bot_fmt_ver = num2str(xml_struct.Attributes(1).Value,'%.1f');

bottoms_node = get_childs(xml_struct,'bottom_line');

if isempty(bottoms_node)
    warning('No bottom definitions in the file');
    bottom_xml = [];
    return;
end

nb_bot = length(bottoms_node);
bottom_xml = cell(1,nb_bot);

for i = 1:nb_bot
    
    bottom_xml{i}.Infos = get_node_att(xml_struct.Children(i));
    
    if isnumeric(bottom_xml{i}.Infos.ChannelID)
        bottom_xml{i}.Infos.ChannelID = num2str(bottom_xml{i}.Infos.ChannelID);
    end
    
    switch bot_fmt_ver
        case '0.1'
            bottom_xml{i}.Bottom = get_bottom_node(xml_struct.Children(i));
        case '0.2'
            bottom_xml{i}.Bottom = get_bottom_node_v2(xml_struct.Children(i));
        case '0.3'
            bottom_xml{i}.Bottom = get_bottom_node_v3(xml_struct.Children(i));
    end
    
    
end

end

% 
%% SUBFUNCTIONS
% 

%%
function bottom = get_bottom_node(bottom_node)

bottom = struct('Range',[],'Tag',[],'Time',[]);

time_node = get_childs(bottom_node,'time');

range_node = get_childs(bottom_node,'range');

tag_node = get_childs(bottom_node,'tag');

range = textscan(range_node.Data,'%f');
bottom.Range = range{1};

time = textscan(time_node.Data,'%s');
bottom.Time = datenum(time{1},'yyyymmddHHMMSSFFF');

tag = textscan(tag_node.Data,'%d');
bottom.Tag = double(tag{1});


end

%%
function bottom = get_bottom_node_v2(bottom_node)

bottom = struct('Sample',[],'Tag',[],'Ping',[]);

ping_node = get_childs(bottom_node,'ping');

sample_node = get_childs(bottom_node,'sample');

tag_node = get_childs(bottom_node,'tag');

sample = textscan(sample_node.Data,'%.d');
bottom.Sample = double(sample{1});

ping = textscan(ping_node.Data,'%.d');
bottom.Ping = double(ping{1});

tag = textscan(tag_node.Data,'%d');
bottom.Tag = double(tag{1});

end

%%
function bottom = get_bottom_node_v3(bottom_node)

bottom = struct('Ping',[],'Sample',[],'Tag',[],'E1',[],'E2',[]);

ping_node = get_childs(bottom_node,'ping');
ping = textscan(ping_node.Data,'%.d');
bottom.Ping = double(ping{1});

sample_node = get_childs(bottom_node,'sample');
sample = textscan(sample_node.Data,'%.d');
bottom.Sample = double(sample{1});

tag_node = get_childs(bottom_node,'tag');
tag = textscan(tag_node.Data,'%d');
bottom.Tag = double(tag{1});

E1_node = get_childs(bottom_node,'E1');
E1 = textscan(E1_node.Data,'%f');
bottom.E1 = E1{1};

E2_node = get_childs(bottom_node,'E2');
E2 = textscan(E2_node.Data,'%f');
bottom.E2 = E2{1};

end




