function [header,output,type]=read_xml0(t_line_ori)

header=[];
output=[];
type='';
t_line_ori=deblank(t_line_ori);
if length(t_line_ori)==1
    return;
end

t_line = regexprep(t_line_ori,'&#x((0\d)|(1\w))|(/L..C)','');

import org.apache.commons.lang.StringEscapeUtils;
s_utils = StringEscapeUtils();
t_line = string(s_utils.unescapeXml(t_line));
try
    xstruct=xml2struct(t_line);
catch
    t_line = strrep(t_line_ori,'&#','u');
    xstruct=xml2struct(t_line);
    if ~isdeployed()
        disp('Some issues with Unicode characters in config XML.');
    end
end
type_tmp=fields(xstruct);
type=type_tmp{1};
switch type
    case 'Configuration'
        [header,output]=read_config_xstruct(xstruct);
    case 'Environment'
        output=read_env_xstruct(xstruct);
    case 'Parameter'
        output=read_params_xstruct(xstruct);
end


end