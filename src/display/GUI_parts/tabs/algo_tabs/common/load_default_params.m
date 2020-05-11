
function load_default_params(src,main_figure,algo_name)
layer=get_current_layer();

if isempty(layer)
    return;
end

curr_disp=get_esp3_prop('curr_disp');
[trans_obj,~]=layer.get_trans(curr_disp);
if isempty(trans_obj)
    return;
end
[idx_algo,found]=find_algo_idx(trans_obj,algo_name);
if found==0
    return
end

[~,~,algo_files]=get_config_files(algo_name);
[~,algo_alt,names]=read_config_algo_xml(algo_files{1});

if strcmp(src.String{src.Value},'--')
    return;
end

idx_algo_xml=strcmpi(names,src.String{src.Value});

if ~isempty(idx_algo_xml)
    varin=algo_alt(idx_algo_xml).init_input_params();
    fields_to_up=fields(varin);
    
    for i=1:numel(fields_to_up)
        if isfield(varin,(fields_to_up{i}))&&~ismember(fields_to_up{i},{'depth_min','depth_max','reg_obj','r_min','r_max'})
            trans_obj.Algo(idx_algo).set_input_param_value(fields_to_up{i},varin.(fields_to_up{i}));
        end
    end
end
set_current_layer(layer);

end
