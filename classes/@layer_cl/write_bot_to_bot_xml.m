function write_bot_to_bot_xml(layer_obj)

% input parser
p = inputParser;
addRequired(p,'layer_obj',@(obj) isa(obj,'layer_cl'));
parse(p,layer_obj);
if isempty(layer_obj)
    return
end

% get current bottom class version
bot_fmt_ver =  bottom_cl.Fmt_Version;

% get filenames
[path_xml,~,bot_file_str] = layer_obj.create_files_str();

for ifile = 1:length(bot_file_str)
    
    % create directory
    if exist(path_xml{ifile},'dir') == 0
        mkdir(path_xml{ifile});
    end
    
    % XML filename
    xml_file = fullfile(path_xml{ifile},bot_file_str{ifile});
    
    % create a docnode and top element
    docNode = com.mathworks.xml.XMLUtils.createDocument('bottom_file');
    bottom_file = docNode.getDocumentElement;
    bottom_file.setAttribute('version',bot_fmt_ver);
    
    % in case a file already exists...
    if exist(xml_file,'file') == 2
        % read the XML file and get its format version
        [bottom_xml_old,bot_fmt_ver_old] = parse_bottom_xml(xml_file);
        for ib = 1:length(bottom_xml_old)
            [~,found] = find_cid_idx(layer_obj,bottom_xml_old{ib}.Infos.ChannelID);
            if found == 0
                if ~strcmpi(bot_fmt_ver_old,bot_fmt_ver)
                    % use the older version
                    bot_fmt_ver = bot_fmt_ver_old;
                    bottom_file.setAttribute('version',bot_fmt_ver);
                end
                docNode = create_bot_xml_node(docNode,bottom_xml_old{ib},bot_fmt_ver_old);
            end
        end
    end
    
    % add node for each channel
    for i = 1:length(layer_obj.Transceivers)
        docNode = layer_obj.Transceivers(i).create_trans_bot_xml_node(docNode,ifile,bot_fmt_ver);
    end
    
    % write XML file
    xmlwrite(xml_file,docNode);
    
end

end
