function add_layers_to_esp3(esp3_obj,new_layers,multi_lay_mode)

all_layer=[esp3_obj.layers new_layers];
all_layers_sorted=all_layer.sort_per_survey_data();

layers=[];
for icell=1:length(all_layers_sorted)
    layers=[layers shuffle_layers(all_layers_sorted{icell},'multi_layer',multi_lay_mode)];
end

if ~isempty(layers)
    esp3_obj.layers=layers;
end

end