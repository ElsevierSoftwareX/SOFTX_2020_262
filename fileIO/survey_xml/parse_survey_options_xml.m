function survey_options_obj=parse_survey_options_xml(xml_file)

survey_options_obj = survey_options_cl();
if ~isfile(xml_file)
    return;
end

xml_struct = parseXML(xml_file);

if ~strcmpi(xml_struct.Name,'survey_options')
    warning('XML file not describing a survey options');
    return;
end

nb_child = length(xml_struct.Children);

idx_child=1:nb_child;

for i = idx_child
    switch xml_struct.Children(i).Name
        case 'options'
            survey_options_obj = survey_options_cl('Options',get_options_node(xml_struct.Children(i)));
        case '#comment'
            continue;
        otherwise
            warning('Unidentified Child in XML');
    end
end


end