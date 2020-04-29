function docNode = create_bot_xml_node(docNode,bot_xml,bot_fmt_ver)

% input parser
p = inputParser;
addRequired(p,'docNode',@(docnode) isa(docNode,'org.apache.xerces.dom.DocumentImpl'));
addRequired(p,'bot_xml',@(x) isstruct(x));
parse(p,docNode,bot_xml);

% initialize bottom node element
bottom_node = docNode.createElement('bottom_line');
bottom_node.setAttribute('Freq',num2str(bot_xml.Infos.Freq,'%.0f'));
bottom_node.setAttribute('ChannelID',bot_xml.Infos.ChannelID);
if isfield(bot_xml.Infos,'NbPings')
    bottom_node.setAttribute('NbPings',num2str(bot_xml.Infos.NbPings,'%d'));
else
    bottom_node.setAttribute('NbPings','0');
end

% get bottom file element
bottom_file = docNode.getDocumentElement;

switch bot_fmt_ver
    case '0.1'
        time_str  = datestr(bot_xml.Bottom.Time,'yyyymmddHHMMSSFFF ');
        time_str  = time_str';
        time_str  = time_str(:)';
        range_str = sprintf('%.4f ',bot_xml.Bottom.Range);
        tag_str   = sprintf('%.0f ',bot_xml.Bottom.Tag);
        
        range_node = docNode.createElement('range');
        range_node.appendChild(docNode.createTextNode(range_str));
        
        time_node = docNode.createElement('time');
        time_node.appendChild(docNode.createTextNode(time_str));
        
        tag_node = docNode.createElement('tag');
        tag_node.appendChild(docNode.createTextNode(tag_str));
        
        bottom_node.appendChild(range_node);
        bottom_node.appendChild(time_node);
        bottom_node.appendChild(tag_node);
        bottom_file.appendChild(bottom_node);
        
    case '0.2'
        ping_str   = sprintf('%.0f ',bot_xml.Bottom.Ping);
        sample_str = sprintf('%.0f ',bot_xml.Bottom.Sample);
        tag_str    = sprintf('%.0f ',bot_xml.Bottom.Tag);
        
        sample_node = docNode.createElement('sample');
        sample_node.appendChild(docNode.createTextNode(sample_str));
        
        ping_node = docNode.createElement('ping');
        ping_node.appendChild(docNode.createTextNode(ping_str));
        
        tag_node = docNode.createElement('tag');
        tag_node.appendChild(docNode.createTextNode(tag_str));
        
        bottom_node.appendChild(sample_node);
        bottom_node.appendChild(ping_node);
        bottom_node.appendChild(tag_node);
        bottom_file.appendChild(bottom_node);
        
    case '0.3'
        % ping number
        ping_str = sprintf('%.0f ',bot_xml.Bottom.Ping);
        ping_node = docNode.createElement('ping');
        ping_node.appendChild(docNode.createTextNode(ping_str));
        bottom_node.appendChild(ping_node);
        
        % bottom sample
        sample_str = sprintf('%.0f ',bot_xml.Bottom.Sample);
        sample_node = docNode.createElement('sample');
        sample_node.appendChild(docNode.createTextNode(sample_str));
        bottom_node.appendChild(sample_node);
        
        % good/bad ping (1/0)
        tag_str = sprintf('%.0f ',bot_xml.Bottom.Tag);
        tag_node = docNode.createElement('tag');
        tag_node.appendChild(docNode.createTextNode(tag_str));
        bottom_node.appendChild(tag_node);
        
        % Roxann E1 "hardness" bottom parameter (energy of the tail of the
        % first echo)
        E1_str = sprintf('%.3f ',bot_xml.Bottom.E1);
        E1_node = docNode.createElement('E1');
        E1_node.appendChild(docNode.createTextNode(E1_str));
        bottom_node.appendChild(E1_node);
        
        % Roxann E2 "roughness" bottom parameter (total energy of the second echo)
        E2_str = sprintf('%.3f ',bot_xml.Bottom.E2);
        E2_node = docNode.createElement('E2');
        E2_node.appendChild(docNode.createTextNode(E2_str));
        bottom_node.appendChild(E2_node);
        
        % add them all to bottom_file element
        bottom_file.appendChild(bottom_node);
        
end
end