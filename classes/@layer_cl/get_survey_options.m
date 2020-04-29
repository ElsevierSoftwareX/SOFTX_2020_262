function survey_options_obj=get_survey_options(layer_obj)
[pathtofile,~]=layer_obj.get_path_files();

fname=fullfile(pathtofile{1},'survey_options.xml');
if ~isfile(fname)
    survey_option_to_xml_file(survey_options_cl,'xml_filename',fname,'subset',1);
end

try
    survey_options_obj=parse_survey_options_xml(fname);
catch
    print_errors_and_warnings([],'warning',sprintf('Could not parse survey option XML file %s',fname));
    survey_options_obj=survey_options_cl();
end
