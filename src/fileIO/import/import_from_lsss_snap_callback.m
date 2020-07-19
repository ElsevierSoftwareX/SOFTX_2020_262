function import_from_lsss_snap_callback(~,~,main_figure)
layer=get_current_layer();

if isempty(layer)
    return;
end

curr_disp=get_esp3_prop('curr_disp');
[trans_obj,idx_freq]=layer.get_trans(curr_disp);
[path_f,file_f,~]=fileparts(layer.Filename{1});


default_filename_snap=fullfile(path_f,[file_f '.snap']);
%default_filename_work=fullfile(path_f,[file_f '.work']);

[Filename,PathToFile]= uigetfile({fullfile(path_f,'*.snap;*.work')}, 'Pick a *.snap or *.work',default_filename_snap,'MultiSelect','off');
if isempty(Filename)||isnumeric(Filename)
    return;
end

trans_obj.set_bot_reg_from_lsss_snap(fullfile(PathToFile,Filename),idx_freq);


display_bottom(main_figure);

display_regions('both');
curr_disp=get_esp3_prop('curr_disp');

curr_disp.setActive_reg_ID({});

set_alpha_map(main_figure,'main_or_mini',union({'main','mini'},layer.ChannelID));



end