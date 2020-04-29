function import_gps_from_csv_callback(~,~,main_figure)
layer=get_current_layer();

if isempty(layer)
return;
end

[path_f,~,~]=fileparts(layer.Filename{1});

[Filename,PathToFile]= uigetfile({fullfile(path_f,'*.csv;*.txt;*.mat')}, 'Pick a csv/txt/mat','MultiSelect','on');


if isempty(Filename)
    return;
end

if ~iscell(Filename)
    if (Filename==0)
        return;
    end
    Filename={Filename};
end


[answer,cancel]=input_dlg_perso(main_figure,'Do you want to apply a time offset?',{'Time offset (in Hours)'},...
    {'%.2f'},{0});

if cancel
    warning('Invalid time offset');
    dt=0;
else
   dt=answer{1}; 
end

gps_data=gps_data_cl.load_gps_from_file(fullfile(PathToFile,Filename));
if isempty(gps_data)
   warndlg_perso(main_figure,'Failed','Could not import GPS Data...')
    return;
end
gps_data.Time=gps_data.Time+dt/24;
layer.replace_gps_data_layer(gps_data);
layer.add_ping_data_to_db([],1);
set_current_layer(layer);

update_grid(main_figure);
update_grid_mini_ax(main_figure);
update_map_tab(main_figure);

end