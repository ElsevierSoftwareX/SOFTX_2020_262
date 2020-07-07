function save_echo_callback(~,~)

layer=get_current_layer();
if isempty(layer)
    return;
end
curr_disp=get_esp3_prop('curr_disp');
[~,idx]=layer.get_trans(curr_disp);
[path_tmp,~,~]=fileparts(layer.Filename{1});
layers_Str=list_layers(layer,'nb_char',80);
fileN=generate_valid_filename(sprintf('%s_%s.png',layers_Str{1},layer.ChannelID{idx}));
[fileN, path_tmp] = uiputfile('*.png',...
    'Save echogram',...
    fullfile(path_tmp,fileN));

if isequal(path_tmp,0)
    return;
else
save_echo('path_echo',path_tmp,'fileN',fileN,'cid','main');


end