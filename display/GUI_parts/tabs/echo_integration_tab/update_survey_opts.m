function update_survey_opts(main_figure)

echo_int_tab_comp=getappdata(main_figure,'EchoInt_tab');

layer_obj=get_current_layer();
if isempty(layer_obj)
    return;
end

survey_options_obj=layer_obj.get_survey_options();

if isempty(survey_options_obj)
    survey_options_obj=survey_options_cl();
end

if isempty(echo_int_tab_comp.cell_w_unit.Value)
    echo_int_tab_comp.cell_w_unit.Value=idx_w;
end

survey_options_obj.Vertical_slice_units=echo_int_tab_comp.cell_w_unit.String{echo_int_tab_comp.cell_w_unit.Value};

survey_options_obj.Vertical_slice_size=str2double(echo_int_tab_comp.cell_w.String);
survey_options_obj.Horizontal_slice_size=str2double(echo_int_tab_comp.cell_h.String);

survey_options_obj.Denoised=echo_int_tab_comp.denoised.Value;
if echo_int_tab_comp.sv_thr_bool.Value
    survey_options_obj.SvThr=str2doubl(echo_int_tab_comp.sv_thr.String);
else
    survey_options_obj.SvThr=-999;
end

survey_options_obj.Shadow_zone=echo_int_tab_comp.shadow_zone.Value;
survey_options_obj.Shadow_zone_height=str2double(echo_int_tab_comp.shadow_zone_h.String);

survey_options_obj.DepthMin=str2double(echo_int_tab_comp.d_min.String);
survey_options_obj.DepthMax=str2double(echo_int_tab_comp.d_max.String);
survey_options_obj.Motion_correction=echo_int_tab_comp.motion_corr.Value;
survey_options_obj.Remove_ST=echo_int_tab_comp.rm_st.Value;

if echo_int_tab_comp.reg_only.Value
    survey_options_obj.IntType = 'By Regions';
    survey_options_obj.IntRef = '';
else
    survey_options_obj.IntType = 'WC';
    survey_options_obj.IntRef = '';
end



layer_obj.create_survey_options_xml(survey_options_obj);

end