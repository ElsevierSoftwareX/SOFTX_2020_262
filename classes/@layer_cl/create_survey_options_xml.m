function create_survey_options_xml(layers_obj,survey_options_obj)

[pathtofile,~]=layers_obj.get_path_files();
pathtofile=unique(pathtofile);

for ip=1:numel(pathtofile)
    fname=fullfile(pathtofile{ip},'survey_options.xml');
    if ~isfile(fname)&&isempty(survey_options_obj)
        survey_option_to_xml_file(survey_options_cl,'xml_filename',fname,'subset',1);
    elseif ~isempty(survey_options_obj)
        survey_option_to_xml_file(survey_options_obj,'xml_filename',fname,'subset',1);
    end
end

end