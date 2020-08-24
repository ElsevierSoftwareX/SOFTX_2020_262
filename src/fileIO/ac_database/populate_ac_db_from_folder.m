function  populate_ac_db_from_folder(main_figure,path_f,varargin)

%% input parser
p = inputParser;

addRequired(p,'main_figure',@ishandle);
addRequired(p,'path_f',@ischar);
addParameter(p,'ac_db_filename','',@ischar);
addParameter(p,'platform_type','Hull',@ischar);
addParameter(p,'transducer_location_type','Hull, keel',@ischar);
addParameter(p,'transducer_orientation_type','Downward-looking',@ischar);
addParameter(p,'deployment_pkey',[],@isnumeric);
addParameter(p,'mission_pkey',[],@isnumeric);
addParameter(p,'overwrite_db',0,@isnumeric);
addParameter(p,'populate_t_navigation',1,@isnumeric);

parse(p,main_figure,path_f,varargin{:});

%%
show_status_bar(main_figure);

if isempty(p.Results.ac_db_filename)
    ac_db_filename = fullfile(path_f,'ac_db.db');
else
    ac_db_filename = p.Results.ac_db_filename;
end

create_ac_database(ac_db_filename,p.Results.overwrite_db);

% connect to database
dbconn = connect_to_db(ac_db_filename);


[~,platform_type_pkey] = get_cols_from_table(dbconn,'t_platform_type','input_cols',{'platform_type'},'input_vals',{{p.Results.platform_type}},...
    'output_cols',{'platform_type_pkey'});
if isempty(platform_type_pkey)
    warning('Invalid platform_type, cannot load this mission');
    hide_status_bar(main_figure);
    return;
end

[~,transducer_orientation_type_pkey] = get_cols_from_table(dbconn,'t_transducer_orientation_type','input_cols',{'transducer_orientation_type'},'input_vals',{{p.Results.transducer_orientation_type}},...
    'output_cols',{'transducer_orientation_type_pkey'});

if isempty(transducer_orientation_type_pkey)
    warning('Invalid transducer_orientation_type, cannot load this mission');
    hide_status_bar(main_figure);
    return;
end

[~,transducer_location_type_pkey] = get_cols_from_table(dbconn,'t_transducer_location_type','input_cols',{'transducer_location_type'},'input_vals',{{p.Results.transducer_location_type}},...
    'output_cols',{'transducer_location_type_pkey'});

if isempty(transducer_location_type_pkey)
    warning('Invalid transducer_location_type, cannot load this mission');
    hide_status_bar(main_figure);
    return;
end



[Filenames,~]=list_ac_files(path_f,0);

if isempty(Filenames)
    disp_perso(main_figure,sprintf('No acoustic files in folder %s. ABORT!!!! :)',path_f));
    hide_status_bar(main_figure);
    return;
end


%Filenames = Filenames(contains(Filenames,'tan1806-D20180712-T12')|contains(Filenames,'tan1806-D20180705-T12'));
%file_pkey = add_files_to_t_file(dbconn,Filenames,'file_path',path_f);

load_bar_comp=getappdata(main_figure,'Loading_bar');
if ~isempty(load_bar_comp)
    load_bar_comp.progress_bar.setText('Getting GPS data from Database...');
end

gps_data_files = get_ping_data_from_db(Filenames,[]);

if p.Results.populate_t_navigation>0
    GPS_only = cellfun(@isempty,gps_data_files);
    GPS_only=~GPS_only+1;
    %GPS_only = 1*ones(1,numel(Filenames));
else
    GPS_only = 3*ones(1,numel(Filenames));
end

Filenames_comp=fullfile(path_f,Filenames);

all_layer=open_file_standalone(Filenames_comp,'','GPSOnly',GPS_only,'load_bar_comp',load_bar_comp);
try
    all_layer.add_ping_data_to_db([],0);
catch err
    print_errors_and_warnings([],'error',err);
    disp_perso(main_figure,'Issue updating GPS data in ping data table from logbook');
end

if isempty(all_layer)
    hide_status_bar(main_figure);
    return;
end

%GPS_only(id_rem) = [];

% idx_gp = find(GPS_only==2);
%
% for ilay = idx_gp
%     if ~isempty(gps_data_files{ilay})
%         all_layer(ilay).GPSData = gps_data_files{ilay};
%     end
% end

if  ~isempty(load_bar_comp)
    load_bar_comp.progress_bar.setText('Sorting Layers');
end
all_layer.load_echo_logbook_db();
all_layers_sorted = all_layer.sort_per_survey_data();

if ~isempty(load_bar_comp)
    load_bar_comp.progress_bar.setText('Shuffling layers');
end
new_layers = [];

for icell = 1:length(all_layers_sorted)
    new_layers = [new_layers shuffle_layers(all_layers_sorted{icell},'multi_layer',0)];
end

if isempty(new_layers)
    hide_status_bar(main_figure);
    return;
end

if ~isempty(load_bar_comp)
    load_bar_comp.progress_bar.setText('Loading Ac db');
end
if isempty(p.Results.deployment_pkey)
    deployment_pkey = add_deployment_struct_to_t_deployment(dbconn,'deployment_struct',init_deployment_struct());
else
    deployment_pkey = p.Results.deployment_pkey;
end


setup_pkey = cell(1,numel(new_layers));

transducer_pkey = cell(1,numel(new_layers));
transceiver_pkey = cell(1,numel(new_layers));


parameters_pkey = cell(1,numel(new_layers));
transect_pkey = cell(1,numel(new_layers));
file_pkey = cell(1,numel(new_layers));
software_pkey = cell(1,numel(new_layers));

if ~isempty(load_bar_comp)
    set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',length(new_layers), 'Value',0);
end

for ilay = 1:length(new_layers)
    lay_obj = new_layers(ilay);
    gps_data = lay_obj.GPSData;
    set(load_bar_comp.progress_bar,  'Value',ilay-1);
    switch lay_obj.Filetype
        case 'EK80'
            [header,~] = read_EK80_config(lay_obj.Filename{1});
            s_manu = 'Simrad';
            s_name = header.ApplicationName;
            s_ver = header.Version;
        case 'EK60'
            s_manu = 'Simrad';
            s_name = 'ER60';
            s_ver = '?';
        case 'ASL'
            s_manu = 'ASL';
            s_name = 'ASL';
            s_ver = '?';
    end
    software_pkey{ilay} = add_software_to_t_software(dbconn,....
        'software_manufacturer',s_manu,...
        'software_name',s_name,...
        'software_version',s_ver,...
        'software_host','',...
        'software_install_date',now,...
        'software_comments','');
    
    [start_time,end_time] = lay_obj.get_time_bound_files();
    
    file_pkey{ilay} = add_files_to_t_file(dbconn,lay_obj.Filename,...
        'file_deployment_key',deployment_pkey,...
        'file_path',path_f,...
        'file_software_key',software_pkey{ilay},...
        'file_start_time',start_time,...
        'file_end_time',end_time);
    
    %file_pkey{ilay} = get_file_pkey_from_ac_db(dbconn,lay_obj.Filename);
    ac_db_struct = survey_data_obj_to_ac_db_struct({lay_obj.SurveyData});
    transect_pkey{ilay} = add_transects_to_t_transect(dbconn,ac_db_struct);
    
    if ~isempty(gps_data)
        try
            depth = lay_obj.Transceivers(1).get_bottom_depth();
            depth_re = resample_data_v2(depth,lay_obj.Transceivers(1).Time,gps_data.Time);
        catch
            depth_re = zeros(1,numel(gps_data.Time));
        end
        
        for ifi = 1:length(file_pkey{ilay})
            idx_keep = gps_data.Time>=start_time(ifi)&gps_data.Time<=end_time(ifi);
            if any(idx_keep)
                try
                    add_nav_to_t_navigation(dbconn,...
                        'navigation_file_key',file_pkey{ilay}(ifi,1),...
                        'navigation_time',gps_data.Time(idx_keep),...
                        'navigation_latitude',gps_data.Lat(idx_keep),...
                        'navigation_longitude',gps_data.Long(idx_keep),...
                        'navigation_depth',depth_re(idx_keep),...
                        'navigation_comments',gps_data.NMEA);
                catch err
                    disp(err.message);
                    warning('populate_ac_db_from_folder:add_nav_to_t_navigation: Error while loading navigation to dB');
                end
            end
        end
        nb_trans = numel(lay_obj.Transceivers);
        parameters_pkey{ilay} = nan(1,nb_trans);
        transceiver_pkey{ilay} = nan(1,nb_trans);
        transducer_pkey{ilay} = nan(1,nb_trans);
        setup_pkey{ilay} = nan(1,nb_trans);
        
        for itrans = 1:nb_trans
            params = lay_obj.Transceivers(itrans).Params;
            config = lay_obj.Transceivers(itrans).Config;
            switch lay_obj.Transceivers(itrans).Mode
                case 'CW'
                    parameters_FM_pulse_type = '';
                case 'FM'
                    
                    if params.FrequencyStart(1)>params.FrequencyEnd(1)
                        parameters_FM_pulse_type = 'linear down-sweep';
                    else
                        parameters_FM_pulse_type = 'linear up-sweep';
                    end
            end
            
            p_temp = add_params_to_t_parameters(dbconn,...
                'parameters_pulse_mode',lay_obj.Transceivers(itrans).Mode,...
                'parameters_pulse_length',round(params.PulseLength(1)*1e6)/1e6,...
                'parameters_pulse_slope',floor(params.Slope(1)*1e4),...
                'parameters_FM_pulse_type',parameters_FM_pulse_type,...
                'parameters_frequency_min',params.FrequencyStart(1),...
                'parameters_frequency_max',params.FrequencyEnd(1),...
                'parameters_power',params.TransmitPower(1),....
                'parameters_comments',''...
                );
            if ~isempty(p_temp)
                parameters_pkey{ilay}(itrans) = p_temp{1,1};
            else
                warning('Problem loading parameters');
            end
            
            switch config.TransceiverType
                case list_GPTs()
                    manu = 'Simrad';
                case list_WBTs()
                    manu = 'Simrad' ;
                otherwise
                    manu = '';
            end
            
            transceiver_pkey_temp = add_transceiver_to_t_transceiver(dbconn,...
                'transceiver_manufacturer',manu,...
                'transceiver_model',config.TransceiverType,...
                'transceiver_serial',config.SerialNumber,...
                'transceiver_frequency_lower',config.FrequencyMinimum,...
                'transceiver_frequency_nominal',config.Frequency,...
                'transceiver_frequency_upper',config.FrequencyMaximum,...
                'transceiver_firmware',num2str(config.TransceiverSoftwareVersion),...
                'transceiver_comments','');
            
            if ~isempty(transceiver_pkey_temp)
                transceiver_pkey{ilay}(itrans) = transceiver_pkey_temp{1,1};
            else
                warning('Problem loading transceiver');
            end
            
            switch config.BeamType
                case 0
                    'Single-beam';
                case {1,65}
                    bt = 'Single-beam, split-aperture';
                otherwise
                    bt = 'Single-beam';
                    
            end
            [~,transducer_beam_type_pkey] = get_cols_from_table(dbconn,'t_transducer_beam_type','input_cols',{'transducer_beam_type'},'input_vals',{{bt}},...
                'output_cols',{'transducer_beam_type_pkey'});
            
            
            transducer_pkey_temp = add_transducer_to_t_transducer(dbconn,...
                'transducer_manufacturer',manu,...
                'transducer_model',deblank(config.TransducerName),...
                'transducer_beam_type_key',transducer_beam_type_pkey{1,1},...
                'transducer_serial',config.TransducerSerialNumber,...
                'transducer_frequency_lower',config.FrequencyMinimum,...
                'transducer_frequency_nominal',config.Frequency,...
                'transducer_frequency_upper',config.FrequencyMaximum,...
                'transducer_psi',round(config.EquivalentBeamAngle*1e2)/1e2,...,...
                'transducer_beam_angle_major',round(config.BeamWidthAlongship*1e2)/1e2,...
                'transducer_beam_angle_minor',round(config.BeamWidthAthwartship*1e2)/1e2,...
                'transducer_comments','');
            
            if ~isempty(transducer_pkey_temp)
                transducer_pkey{ilay}(itrans) = transducer_pkey_temp{1,1};
            else
                warning('Problem loading transducer');
            end
            
            setup_pkey_temp = add_setup_to_t_setup(dbconn,...
                'setup_platform_type_key',platform_type_pkey{1,1},...
                'setup_parameters_key',parameters_pkey{ilay}(itrans),...
                'setup_transducer_key',transducer_pkey{ilay}(itrans),...
                'setup_transceiver_key', transceiver_pkey{ilay}(itrans),...
                'setup_transducer_location_type_key',transducer_location_type_pkey{1,1},...
                'setup_transducer_location_x',config.TransducerOffsetX,...
                'setup_transducer_location_y',config.TransducerOffsetY,...
                'setup_transducer_location_z',config.TransducerOffsetZ,...
                'setup_transducer_depth',config.TransducerOffsetX,...
                'setup_transducer_orientation_type_key',transducer_orientation_type_pkey{1,1},...
                'setup_transducer_orientation_vx',config.TransducerAlphaX,...
                'setup_transducer_orientation_vy',config.TransducerAlphaY,...
                'setup_transducer_orientation_vz',config.TransducerAlphaZ,...
                'setup_comments','');
            
            if ~isempty(setup_pkey_temp)
                setup_pkey{ilay}(itrans) = setup_pkey_temp{1,1};
            else
                warning('Problem loading setup');
            end
        end
        
    end
    add_many_to_many(dbconn,'t_file_setup','file_key','setup_key',file_pkey{ilay},setup_pkey{ilay});
    set(load_bar_comp.progress_bar,  'Value',ilay-1);
end

if ~isempty(p.Results.mission_pkey)
    for i_mission = 1:numel(p.Results.mission_pkey)
        add_many_to_many(dbconn,'t_mission_deployment','deployment_key','mission_key',deployment_pkey,p.Results.mission_pkey(i_mission));
    end
end

%% update deployment limits from navigation data

% get current values
sql_query = sprintf('SELECT deployment_northlimit,deployment_southlimit,deployment_eastlimit,deployment_westlimit FROM t_deployment');
init_vals = dbconn.fetch(sql_query);

% get navigation data
file_pkeys = cell2mat(file_pkey')';
str_cell = cellfun(@num2str,num2cell(file_pkeys),'un',0);
sql_query = sprintf(['SELECT COUNT(navigation_latitude)'....
    'from t_navigation where navigation_file_key IN (%s)'],strjoin(str_cell(:),','));
nb_vals = dbconn.fetch(sql_query);

if nb_vals{1,1} > 0
    
    [lat_min,lat_max,lon_min,lon_max] = get_lat_lon_min_max_from_file_pkey(dbconn,file_pkeys);
    %[t_min,t_max] = get_t_min_max_from_file_pkey(dbconn,file_pkeys);
    
    if isnumeric(init_vals{1,1})
        if init_vals{1,1}<90
            lat_max = nanmax(lat_max,init_vals{1,1});
        end
    end
    if isnumeric(init_vals{1,2})
        if init_vals{1,2}>-90
            lat_min = nanmin(lat_max,init_vals{1,2});
        end
    end
    if isnumeric(init_vals{1,3})
        if init_vals{1,3}<180
            lon_max = nanmax(lon_max,init_vals{1,3});
        end
    end
    if isnumeric(init_vals{1,4})
        if init_vals{1,4}>-180
            lon_min = nanmin(lon_min,init_vals{1,4});
        end
    end
    
    % update nav limits in t_deployment
    sql_query = sprintf('UPDATE t_deployment SET deployment_northlimit=%f,deployment_southlimit=%f,deployment_eastlimit=%f,deployment_westlimit=%f',lat_max,lat_min,lon_max,lon_min);
    dbconn.exec(sql_query);
    
end

% close database connection
dbconn.close();

%%
hide_status_bar(main_figure);

end