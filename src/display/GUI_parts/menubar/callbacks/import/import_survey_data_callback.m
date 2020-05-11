function import_survey_data_callback(~,~,main_figure)
layers=get_esp3_prop('layers');

if ~isempty(layers)
    for i=1:length(layers)
        switch layers(i).Filetype
            case {'EK80','EK60','ASL'}
                layers(i).add_survey_data_db();
        end
    end
else
    return;
end

set_esp3_prop('layers',layers);
update_tree_layer_tab(main_figure);
display_survdata_lines(main_figure);
update_info_panel([],[],1);
end
