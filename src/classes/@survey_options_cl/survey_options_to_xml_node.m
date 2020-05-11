function xml_node=survey_options_to_xml_node(survey_opt_obj,docNode,subset)

if subset==1   
    fields_opts={'Soundspeed' 'Temperature' 'Salinity' 'DepthMin','DepthMax','RangeMin','RangeMax','RefRangeMin','RefRangeMax',...
        'Vertical_slice_size','Vertical_slice_units','Horizontal_slice_size','SvThr','Denoised','Shadow_zone','Shadow_zone_height','Motion_correction',...
        'IntType','IntRef'};
else
    fields_opts=fields(survey_opt_obj);
end

xml_node = docNode.createElement('options');

for i=1:length(fields_opts)

    if isnumeric(survey_opt_obj.(fields_opts{i}))||islogical(survey_opt_obj.(fields_opts{i}))
        xml_node.setAttribute(fields_opts{i}, vec2delem_str(double(survey_opt_obj.(fields_opts{i})),';','%.2f '));
    else
        xml_node.setAttribute(fields_opts{i},survey_opt_obj.(fields_opts{i}));
    end
    
    
end
