function load_svp_esp3_callback(~,~,main_figure) 
layer=get_current_layer();

if isempty(layer)
    return;
end
    
[path_file,~,~]=fileparts(layer.Filename{1});
[svp_filename,svp_path]= uigetfile( {fullfile(path_file,'*.espsvp')}, 'Pick an SVP file (ESP3 format) ','MultiSelect','off');  

if ~(svp_filename~=0)
    return;
end
layer.EnvData.load_svp(fullfile(svp_path,svp_filename));
update_environnement_tab(main_figure,1);
layer.layer_computeSpSv();