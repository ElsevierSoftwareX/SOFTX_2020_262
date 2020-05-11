function [bot_ver,reg_ver,comment] = load_bot_regs(layer,varargin)

% input parser
% for both bot_ver and reg_ver:
%   empty: no loading
%   -1: load xml file
%   0: load latest db version (or xml file if no db)
%   n: load closest version to version n from db (or xml file if no db)
p = inputParser;
addRequired(p,'layer',@(obj) isa(obj,'layer_cl'));
addParameter(p,'bot_ver',-1);
addParameter(p,'reg_ver',-1);
addParameter(p,'IDs',[]);
addParameter(p,'Frequencies',[]);
addParameter(p,'Channels',{});
parse(p,layer,varargin{:});


%% bottom
bot_ver = p.Results.bot_ver;
try
    if ~isempty(bot_ver)
        if bot_ver >= 0
            % when asked to load bottom from database, we actually overwrite
            % the XML file with the desired version in the database
            bot_ver = layer.create_bot_xml_from_db('bot_ver',bot_ver);
        end
        xml_parsed = layer.add_bottoms_from_bot_xml('Channels',p.Results.Channels,'Frequencies',p.Results.Frequencies,'Version',bot_ver);
        if ~all(xml_parsed==0)
            fprintf('Bottom loaded from xml file.\n');
        else
            fprintf('No bottom loaded.\n');
        end
    end
catch err
    str_lay=list_layers(layer);
    disp_perso([],sprintf('Could not load bottom for layer %s',str_lay{1}));
    print_errors_and_warnings([],'error',err);
end

%% regions
reg_ver = p.Results.reg_ver;
comment = '';
try
    if ~isempty(reg_ver)
        if reg_ver >= 0
            % when asked to load regions from database, we actually overwrite
            % the XML file with the desired version in the database
            [reg_ver,comment] = layer.create_reg_xml_from_db('reg_ver',reg_ver);
        end
        xml_parsed = layer.add_regions_from_reg_xml([],'Channels',p.Results.Channels,'Frequencies',p.Results.Frequencies,'Version',reg_ver);
        if ~all(xml_parsed==0)
            fprintf('Regions loaded from xml file.\n');
        else
            fprintf('No regions loaded.\n');
        end
    end
    
catch err
    str_lay=list_layers(layer);
    disp_perso([],sprintf('Could not load regions for layer %s',str_lay{1}));
    print_errors_and_warnings([],'error',err);
end

