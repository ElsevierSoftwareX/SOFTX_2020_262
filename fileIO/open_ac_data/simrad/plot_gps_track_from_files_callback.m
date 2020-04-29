function  plot_gps_track_from_files_callback(~,~,main_figure)

%% get a path

layer = get_current_layer();

if ~isempty(layer)
    [path_lay,~] = layer.get_path_files();
    if ~isempty(path_lay)
        file_path = path_lay{1};
    else
        file_path = pwd;
    end
else
    file_path = pwd;
end


%% get files


Filename=get_compatible_ac_files(file_path);

%% manage file list

if isempty(Filename)
    return;
end





%% open all files (GPS only)

% status bar
show_status_bar(main_figure);
load_bar_comp = getappdata(main_figure,'Loading_bar');

% read all files
new_layers = open_file_standalone(Filename,'','GPSOnly',1,'load_bar_comp',load_bar_comp);

if isempty(new_layers)
    return;
end
curr_disp=get_esp3_prop('curr_disp');

%% display GPS

new_layers.load_echo_logbook_db();

map_obj = map_input_cl.map_input_cl_from_obj(new_layers,'Basemap',curr_disp.Basemap);
if isempty(map_obj)
    return;
end
hfigs = getappdata(main_figure,'ExternalFigures');

hfig = new_echo_figure(main_figure,'Tag','nav','Toolbar','esp3','MenuBar','esp3');
[folders,~]=new_layers.get_path_files();
map_obj.display_map_input_cl('hfig',hfig,'main_figure',main_figure,'oneMap',1,'echomaps',unique(folders));

hfigs = [hfigs hfig];

setappdata(main_figure,'ExternalFigures',hfigs);
hide_status_bar(main_figure);

end
