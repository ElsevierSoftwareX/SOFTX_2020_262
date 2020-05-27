function create_context_menu_main_echo(main_figure)

% prep
axes_panel_comp = getappdata(main_figure,'Axes_panel');
curr_disp=get_esp3_prop('curr_disp');
layer = get_current_layer();
[~,idx_freq] = layer.get_trans(curr_disp);

delete(findobj(ancestor(axes_panel_comp.bad_transmits,'figure'),'Type','UiContextMenu','-and','Tag','btCtxtMenu'));

% initialize context menu
context_menu = uicontextmenu(ancestor(axes_panel_comp.bad_transmits,'figure'),'Tag','btCtxtMenu');
axes_panel_comp.bad_transmits.UIContextMenu = context_menu;

% Ping Analysis
analysis_menu = uimenu(context_menu,'Label','Ping Analysis');
uimenu(analysis_menu,'Label','Plot Profiles',         'Callback',{@plot_profiles_callback,main_figure});
uimenu(analysis_menu,'Label','Display Ping Impedance','Callback',{@display_ping_impedance_cback,main_figure,[],1});
uimenu(analysis_menu,'Label','Plot Ping TS Spectrum', 'Callback',{@plot_ping_spectrum_callback,main_figure});
uimenu(analysis_menu,'Label','Plot Ping Sv Spectrum', 'Callback',{@plot_ping_sv_spectrum_callback,main_figure});

% ST and Tracks
data_menu = uimenu(context_menu,'Label','ST and Tracks');
uimenu(data_menu,'Label','Remove Tracks','Callback',{@remove_tracks_cback,main_figure});
uimenu(data_menu,'Label','Remove ST',    'Callback',{@remove_ST_cback,main_figure});

% Survey Data
survey_menu = uimenu(context_menu,'Label','Survey Data');
uimenu(survey_menu,'Label','Edit Voyage Info',                      'Callback',{@edit_trip_info_callback,main_figure});
uimenu(survey_menu,'Label','Edit/Add Survey Data',                  'Callback',{@edit_survey_data_callback,main_figure,0});
uimenu(survey_menu,'Label','Edit/Add Survey Data for this file',    'Callback',{@edit_survey_data_curr_file_callback,main_figure});
uimenu(survey_menu,'Label','Edit/Add Survey Data for this transect','Callback',{@edit_survey_data_curr_transect_callback,main_figure});
uimenu(survey_menu,'Label','Remove Survey Data',                    'Callback',{@edit_survey_data_callback,main_figure,1});
uimenu(survey_menu,'Label','Split Transect Here',                   'Callback',{@split_transect_callback,main_figure});

% Tools
tools_menu = uimenu(context_menu,'Label','Tools');
uimenu(tools_menu,'Label','Correct this transect position based on cable angle and towbody depth','Callback',{@correct_pos_angle_depth_sector_cback,main_figure});

% Bad Transmits
bt_menu = uimenu(context_menu,'Label','Bad Transmits');
uifreq  = uimenu(bt_menu,'Label','Copy to other channels');
uimenu(uifreq,'Label','all',                  'Callback',{@copy_bt_cback,main_figure,[]});
uimenu(uifreq,'Label','choose which Channels','Callback',{@copy_bt_cback,main_figure,1});

% Configuration
config_menu = uimenu(context_menu,'Label','Configuration');
uimenu(config_menu,'Label','Display Ping Configuration','Callback',{@disp_ping_config_params_callback,main_figure});
if strcmpi(layer.Filetype,'EK80')
    uimenu(config_menu,'Label','Save current configuration to XML file (Simrad format)',    'Callback',{@save_config_to_file_cback,main_figure});
    uimenu(config_menu,'Label','Reload current configuration from XML file (Simrad format)','Callback',{@reload_config_file_cback,main_figure});
end

% Copy
copy_menu = uimenu(context_menu,'Label','Copy');
uimenu(copy_menu,'Label','To clipboard','Callback',{@copy_echo_to_clipboard_callback,main_figure});



end

%%
% subfunctions
%

%%
function save_config_to_file_cback(src,~,main_figure)
curr_disp=get_esp3_prop('curr_disp');
layer = get_current_layer();
[trans_obj,~] = layer.get_trans(curr_disp);

for ifi = 1:length(layer.Filename)
    [path_f,fileN,~] = fileparts(layer.Filename{ifi});
    config_file = fullfile(path_f,[fileN '_config.xml']);
    if ~isfile(config_file)
        fid = fopen(config_file,'w+');
        if fid>0
            fwrite(fid,trans_obj.Config.XML_string,'char');
            fclose(fid);
        end
    end
    open_txt_file(config_file);
    
end
end

%%
function reload_config_file_cback(src,~,main_figure)
layer = get_current_layer();
trans_obj = layer.Transceivers;

for ifi = 1:length(layer.Filename)
    [path_f,fileN,~] = fileparts(layer.Filename{ifi});
    config_file = fullfile(path_f,[fileN '_config.xml']);
    if isfile(config_file)
        try
            
            fid = fopen(config_file,'r');
            t_line = fread(fid,'*char');
            t_line = t_line';
            fclose(fid);
            [~,output,type] = read_xml0(t_line);%50% faster than the old version!
            switch type
                case 'Configuration'
                    for i = 1:length(trans_obj)
                        
                        idx = find(strcmp(deblank( trans_obj(i).Config.ChannelID),deblank(cellfun(@(x) x.ChannelIdShort,output,'un',0))));
                        if ~isempty(idx)
                            config_obj = config_obj_from_xml_struct(output(idx),t_line);
                            if~isempty(config_obj)
                                
                                trans_obj(i).Config = config_obj;
                            end
                        end
                    end
            end
        catch
            warning('Could not read Config for file %s\n',fileN);
        end
        break;
    end
end
end

%%
function copy_echo_to_clipboard_callback(src,~,main_figure)
save_echo(main_figure,[],'-clipboard','main');
end



%%
function copy_bt_cback(src,~,main_figure,ifreq)

layer = get_current_layer();
curr_disp=get_esp3_prop('curr_disp');
[~,idx_freq] = layer.get_trans(curr_disp);


if ~isempty(ifreq)
    idx_other = setdiff(1:numel(layer.Frequencies),idx_freq);
    if isempty(idx_other)
        return;
    end
    
    list_freq_str = cellfun(@(x,y) sprintf('%.0f kHz: %s',x,y),num2cell(layer.Frequencies(idx_other)/1e3), deblank(layer.ChannelID(idx_other)),'un',0);
    
    if isempty(list_freq_str)
        return;
    end
    
    [ifreq,val] = listdlg_perso(main_figure,'',list_freq_str);
    if val==0 || isempty(ifreq)
        return;
    end
    ifreq = layer.find_cid_idx(layer.ChannelID(idx_other(ifreq)));
end

[bots,ifreq] = layer.generate_bottoms_for_other_freqs(idx_freq,ifreq);

for i = 1:numel(ifreq)
    old_bot = layer.Transceivers(ifreq(i)).Bottom;
    bots(i).Sample_idx = old_bot.Sample_idx;
    bots(i).Tag = (old_bot.Tag>0&bots(i).Tag>0);
    layer.Transceivers(ifreq(i)).Bottom = bots(i);
    add_undo_bottom_action(main_figure,layer.Transceivers(ifreq(i)),old_bot,bots(i));
end

set_alpha_map(main_figure,'main_or_mini',union({'main','mini'},layer.ChannelID(ifreq)),'update_under_bot',0,'update_cmap',0);

end

%%
function correct_pos_angle_depth_sector_cback(src,~,main_figure)


layer = get_current_layer();

if isempty(layer)
    return;
end

axes_panel_comp = getappdata(main_figure,'Axes_panel');
curr_disp=get_esp3_prop('curr_disp');
[trans_obj,idx_freq] = layer.get_trans(curr_disp);
trans = trans_obj;

ax_main = axes_panel_comp.main_axes;
x_lim = double(get(ax_main,'xlim'));

cp = ax_main.CurrentPoint;
x = cp(1,1);

x = nanmax(x,x_lim(1));
x = nanmin(x,x_lim(2));

xdata = trans.get_transceiver_pings();

[~,idx_ping] = nanmin(abs(xdata-x));

time = trans.Time;
t_n = time(idx_ping);


prompt = {'Towing cable angle (in degree)','Towbody depth'};
defaultanswer = {25,500};


[answer,cancel] = input_dlg_perso(main_figure,'Correct position',prompt,...
    {'%.0f' '%.1f'},defaultanswer);
if cancel
    return;
end

if isempty(answer)
    return;
end

angle_deg = answer{1};

if isnan(angle_deg)
    warning('Invalid Angle');
    return;
end

depth_m = answer{2};

if isnan(depth_m)
    warning('Invalid Depth');
    return;
end

[surv,~] = layer.get_survdata_at_time(t_n);

[~,idx_ts] = nanmin(abs(time-surv.StartTime));
[~,idx_te] = nanmin(abs(time-surv.EndTime));

idx_t = idx_ts:idx_te;

curr_disp=get_esp3_prop('curr_disp');
[trans_obj,~] = layer.get_trans(curr_disp);
gps_data = trans_obj.GPSDataPing;

LongLim = [nanmin(gps_data.Long(idx_t)) nanmax(gps_data.Long(idx_t))];

LatLim = [nanmin(gps_data.Lat(idx_t)) nanmax(gps_data.Lat(idx_t))];

ext_lat_lon_lim_v2(LatLim,LongLim,0.3);

[new_lat,new_long,hfig] = correct_pos_angle_depth(gps_data.Lat(idx_t),gps_data.Long(idx_t),angle_deg,depth_m,proj_i);

war_str = 'Would you like to use this corrected track (in red)?';
choice = question_dialog_fig(main_figure,'',war_str);
close(hfig);

switch choice
    case 'Yes'
        trans_obj.GPSDataPing.Lat(idx_t) = new_lat;
        trans_obj.GPSDataPing.Long(idx_t) = new_long;
        layer.replace_gps_data_layer(trans_obj.GPSDataPing);
        export_gps_to_csv_callback([],[],main_figure,layer.Unique_ID,'_gps');
    case 'No'
        return;
        
end

update_map_tab(main_figure);
update_grid(main_figure);
update_grid_mini_ax(main_figure);


end