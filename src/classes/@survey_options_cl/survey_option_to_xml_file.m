function survey_option_to_xml_file(survey_options_obj,varargin)
p = inputParser;

addRequired(p,'survey_options_obj',@(x) isa(x,'survey_options_cl'));
addParameter(p,'xml_filename',fullfile(pwd,'survey_options.xml'),@ischar);
addParameter(p,'subset',1,@isnumeric);
addParameter(p,'open_file',false,@islogical);

parse(p,survey_options_obj,varargin{:});

docNode = com.mathworks.xml.XMLUtils.createDocument('survey_options');
main_node=docNode.getDocumentElement;

options_node = survey_options_obj.survey_options_to_xml_node(docNode,1);

main_node.appendChild(options_node);

[path_f,f,e]=fileparts(p.Results.xml_filename);
if ~isfolder(path_f)
    try
        stat=mkdir(path_f);
        if stat==0
             path_f=pwd;
        end
    catch
        path_f=pwd;
    end
end
f_out=fullfile(path_f,[f e]);

xmlwrite(f_out,docNode);
type(f_out);
if p.Results.open_file
    open_txt_file(f_out);
end

