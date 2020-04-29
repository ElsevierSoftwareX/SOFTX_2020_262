function ver_bot = create_bot_xml_from_db(layer_obj,varargin)

% input parser
p = inputParser;
addRequired(p,'layer_obj',@(obj) isa(obj,'layer_cl'));
addParameter(p,'bot_ver',-1);
parse(p,layer_obj,varargin{:});
ver_bot = p.Results.bot_ver;

if isempty(p.Results.bot_ver)
    return;
end
if p.Results.bot_ver<0
    return;
end

[path_xml,~,bot_file_str] = layer_obj.create_files_str();

for ifile = 1:length(path_xml)
    
    if exist(path_xml{ifile},'dir')==0
        mkdir(path_xml{ifile});
    end
    
    dbfile = fullfile(path_xml{ifile},'bot_reg.db');
    
    % exit if database file does not exist
    if exist(dbfile,'file')==0
        
        fprintf('Region/Bottom database file %s does not exist.\n',dbfile);
        ver_bot = -1;
        
    else
        
        % connect to database
        dbconn = sqlite(dbfile,'connect');
        
        bot_xml_version = dbconn.fetch(sprintf('select bot_XML,Version from bottom where Filename is "%s"',bot_file_str{ifile}));
        
        if isempty(bot_xml_version)           
            fprintf('No data in Region/Bottom database for file %s.\nWill use existing XML file.\n',bot_file_str{ifile});
            ver_bot = -1;
            
        else
        
            % get all versions available
            ver_num = cell2mat(bot_xml_version(:,2));
            
            if p.Results.bot_ver==0
                % requesting latest version
                [ver_bot,idx_xml] = nanmax(ver_num);
            else
                % requesting specific version
                idx_xml = find(ver_num<=p.Results.bot_ver,1,'last');
                ver_bot = ver_num(idx_xml);
            end
            
            % getting xml from that version
            xml_str = bot_xml_version{idx_xml,1};
            
            % open xml file and overwrite it
            fid = fopen(fullfile(path_xml{ifile},bot_file_str{ifile}),'w');
            fprintf(fid,'%s', xml_str);
            fclose(fid);
            
            fprintf('Bottom xml file overwritten with bottom version %d from Region/Bottom database file %s.\n',ver_bot,dbfile);
            
        end
        
        % disconnect from database
        close(dbconn);
        
        
    end
    
end


