function save_sliced_transect_to_xls_callback(~,~,main_figure,save_bool)
layer=get_current_layer();
if isempty(layer)
    return;
end

curr_disp=get_esp3_prop('curr_disp');
[trans_obj,idx_freq]=layer.get_trans(curr_disp);

survey_options_obj=layer.get_survey_options();

idx_reg=trans_obj.find_regions_type('Data');


[path_tmp,fileN,~]=fileparts(layer.Filename{1});


if save_bool>0
    path_tmp = uigetdir(path_tmp,...
        'Save Sliced transect to folder');
    if isequal(path_tmp,0)
        return;
    end
end

load_bar_comp=show_status_bar(main_figure);
load_bar_comp.progress_bar.setText('Exporting Sliced transect...');


[output_2D,output_2D_type,~,~,~]=layer.export_slice_transect_to_xls(...
    'idx_main_freq',idx_freq,'idx_sec_freq',[],...
    'survey_options',survey_options_obj,...
    'idx_regs',idx_reg,...
    'output_f',fullfile(path_tmp,fileN),...
    'load_bar_comp',load_bar_comp);

reg_temp=trans_obj.create_WC_region(...
    'Ref','Surface',...
    'Cell_w',survey_options_obj.Vertical_slice_size,...
    'Cell_w_unit',survey_options_obj.Vertical_slice_units,...
    'Cell_h',survey_options_obj.Horizontal_slice_size,...,
    'Cell_h_unit','meters');


for it=1:numel(output_2D{idx_freq})
    if ~strcmpi(output_2D_type{idx_freq}{it},'Shadow')
        reg_temp.Reference=output_2D_type{idx_freq}{it};
        try
            reg_temp.display_region(output_2D{idx_freq}{it},'main_figure',main_figure,'Name',['Sliced Transect 2D (' output_2D_type{idx_freq}{it} ' Ref)']);
        catch
            disp_perso(main_figure,['Could not display sliced transect (' output_2D_type{idx_freq}{it} ' Referenced)']);
        end
    end
end




load_bar_comp.progress_bar.setText('Done...');
pause(0.5);
load_bar_comp.progress_bar.setText('');
hide_status_bar(main_figure);

end