function compute_svp_esp3_callback(~,~,main_figure)

layer=get_current_layer();

if isempty(layer)
    return;
end
layer.EnvData.svp_from_ctd();

update_environnement_tab(main_figure,1);
