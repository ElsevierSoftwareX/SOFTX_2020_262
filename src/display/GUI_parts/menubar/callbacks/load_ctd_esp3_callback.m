function load_ctd_esp3_callback(~,~,main_figure)
layer=get_current_layer();

if isempty(layer)
    return;
end

[path_file,~,~]=fileparts(layer.Filename{1});
[ctd_filename,ctd_path]= uigetfile( {fullfile(path_file,'*.espctd*')}, 'Pick a CTD file (ESP3 format)','MultiSelect','off');
if ~(ctd_filename~=0)
    return;
end

layer.EnvData.load_ctd(fullfile(ctd_path,ctd_filename));
update_environnement_tab(main_figure,1);
layer.layer_computeSpSv();