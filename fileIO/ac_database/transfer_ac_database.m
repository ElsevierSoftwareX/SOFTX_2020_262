function data_to_load = transfer_ac_database(db_src,db_dest,varargin)

%% input parser

p = inputParser;
addRequired(p,'db_src',@ischar);
addRequired(p,'db_dest',@ischar);
addParameter(p,'backup_and_remove_src',0,@isnumeric);
addParameter(p,'clear_dest',0,@isnumeric);
parse(p,db_src,db_dest,varargin{:});

%% Listing all tables, in the right order to ensure dependences
table_list = {...
    't_ship_type' ...
    't_transducer_location_type' ...
    't_transducer_orientation_type' ...
    't_transducer_beam_type' ...
    't_platform_type' ...
    't_deployment_type' ...
    't_ship' ...
    't_ancillary' ...
    't_parameters' ...
    't_transceiver' ...
    't_transducer' ...
    't_software' ...
    't_mission' ...
    't_deployment' ...
    't_setup' ...
    't_calibration' ...
    't_file' ....
    't_navigation' ...
    't_transect' ...
    't_file_setup' ...
    't_file_transect' ...
    't_mission_deployment' ...
    't_file_ancillary' ...
    };

pkey_list = {...
    'ship_type_pkey' ...
    'transducer_location_type_pkey' ...
    'transducer_orientation_type_pkey' ...
    'transducer_beam_type_pkey' ...
    'platform_type_pkey' ...
    'deployment_type_pkey' ...
    'ship_pkey' ...
    'ancillary_pkey' ...
    'parameters_pkey' ...
    'transceiver_pkey' ...
    'transducer_pkey' ...
    'software_pkey' ...
    'mission_pkey' ...
    'deployment_pkey' ...
    'setup_pkey' ...
    'calibration_pkey' ...
    'file_pkey' ....
    'navigation_pkey' ...
    'transect_pkey' ...
    'file_setup_pkey' ...
    'file_transect_pkey' ...
    'mission_deployment_pkey' ...
    'file_ancillary_pkey' ...
    };

ukey_list = {...
    {'ship_type_pkey','ship_type'} ...
    {'transducer_location_type_pkey','transducer_location_type'} ...
    {'transducer_orientation_type_pkey','transducer_orientation_type'} ...
    {'transducer_beam_type_pkey','transducer_beam_type'} ...
    {'platform_type_pkey','platform_type'} ...
    {'deployment_type_pkey','deployment_type'} ...
    {'ship_IMO','ship_type_key','ship_name'} ...
    {'ancillary_type,ancillary_manufacturer','ancillary_model','ancillary_serial'} ...
    {'parameters_pulse_mode','parameters_pulse_length','parameters_pulse_slope','parameters_FM_pulse_type','parameters_frequency_min','parameters_frequency_max','parameters_power'} ...
    {'transceiver_model','transceiver_serial','transceiver_frequency_nominal'} ...
    {'transducer_model','transducer_serial','transducer_frequency_nominal'} ...
    {'software_manufacturer','software_name','software_version','software_host','software_install_date'} ...
    {'mission_name'} ...
    {'deployment_type_key','deployment_ship_key','deployment_id','deployment_operator','deployment_start_date','deployment_end_date','deployment_start_BODC_code','deployment_end_BODC_code'} ...
    {'setup_platform_type_key','setup_transceiver_key','setup_transducer_key','setup_parameters_key','setup_transducer_location_x','setup_transducer_location_y','setup_transducer_location_z','setup_transducer_depth','setup_transducer_orientation_type_key','setup_transducer_orientation_vx','setup_transducer_orientation_vy','setup_transducer_orientation_vz'} ...
    {'calibration_date','calibration_setup_key'} ...
    {'file_path','file_name'} ...
    {'navigation_time','navigation_file_key'} ...
    {'transect_snapshot','transect_stratum','transect_type','transect_number','transect_start_time','transect_end_time'} ...
    {'file_key','setup_key'} ...
    {'file_key','transect_key'} ...
    {'mission_key','deployment_key'} ...
    {'file_key','ancillary_key'} ...
    };

fkey_list = {...
    {} ...
    {} ...
    {} ...
    {} ...
    {} ...
    {} ...
    {{'ship_type_key','t_ship_type'}} ...
    {} ...
    {} ...
    {} ...
    {{'transducer_beam_type_key','t_transducer_beam_type'}} ...
    {} ...
    {} ...
    {{'deployment_type_key','t_deployment_type'},{'deployment_ship_key','t_ship'}} ...
    {{'setup_platform_type_key','t_platform_type'},{'setup_transceiver_key','t_transceiver'},{'setup_transducer_key','t_transducer'},{'setup_transducer_location_type_key','t_transducer_location_type'},{'setup_transducer_orientation_type_key','t_transducer_orientation_type'},{'setup_parameters_key','t_parameters'}} ...
    {{'calibration_setup_key','t_setup'}} ...
    {{'file_software_key','t_software'},{'file_deployment_key','t_deployment'}} ...
    {{'navigation_file_key','t_file'}} ...
    {} ...
    {{'file_key','t_file'},{'setup_key','t_setup'}} ...
    {{'file_key','t_file'},{'transect_key','t_transect'}} ...
    {{'mission_key','t_mission'},{'deployment_key','t_deployment'}} ...
    {{'ancillary_key','t_ancillary'},{'file_key','t_file'}} ...
    };%{'key_name','table'}


%% connection to source and destination databases

%db_source = 'pgdb.niwa.local:acoustic_test:load';
%db_dest = 'pgdb.niwa.local:acoustic_test:esp3';
fprintf('Connecting to source database %s... ',db_src);
db_src_conn = connect_to_db(db_src);
fprintf('OK.\n');
fprintf('Connecting to destination database %s... ',db_dest);
db_dest_conn = connect_to_db(db_dest);
fprintf('OK.\n');

%% clearing destination database (when loading MINIDB to LOAD)
if p.Results.clear_dest>0
    fprintf('Clearing destination database %s... ',db_dest);
    sql_query_truncate = sprintf('TRUNCATE %s',strjoin(table_list,','));
    out = db_dest_conn.exec(sql_query_truncate);
    fprintf('DONE.\n');
end

%% initialize backup and removal of source database (when loading LOAD to ESP3)
if p.Results.backup_and_remove_src > 0
    
    try
        sql_query = 'SELECT MAX(load_pkey) from t_load';
        tmp = db_src_conn.fetch(sql_query); %not sure what this for?
    catch
        create_t_load(db_src_conn)
    end
    
    % creating info about LOAD-to-ESP3 loading event
    struct_load.load_user     = {getenv('USERNAME')};
    struct_load.load_time     = {datestr(now,'yyyy-mm-dd HH:MM:SS')};
    struct_load.load_comments = {sprintf('Created from %s',db_src)};
    
    % insert loading event in t_load
    fprintf('Inserting information about load event in load.t_load... ');
    load_id = insert_data_controlled(db_src_conn,'t_load',struct_load,struct_load,'load_pkey');
    fprintf('DONE.\n');
    
end


%% reading source data per table, and calculating max pkey value
fprintf('Reading contents of tables in source database/schema and calculating max pkey values...\n');
for it = 1:numel(table_list)
    
    fprintf('	Reading %s...\n',table_list{it});
    
    switch table_list{it}
        
        case 't_navigation_nope'
            data_to_load.t_navigation = [];
            f_pkeys = data_to_load.t_file.file_pkey;
            temp_table = [];
            for i_fk = f_pkeys(:)'
                sql_query = sprintf('SELECT * FROM %s WHERE navigation_file_key=%d','t_navigation',i_fk);
                tmp = db_src_conn.fetch(sql_query);
                temp_table = [temp_table;tmp];
            end
            
            
            
        otherwise
            % query load schema for table
            sql_query = sprintf('SELECT * FROM %s',table_list{it});
            temp_table = db_src_conn.fetch(sql_query);
            
    end
    
    % saving results as structure in data_to_load
    if ~isempty(temp_table)
        if istable(temp_table)
            data_to_load.(table_list{it}) = table2struct(temp_table,'ToScalar',true);
        else
            data_to_load.(table_list{it}) = [];
        end
    else
        data_to_load.(table_list{it}) = [];
    end
    if ~isempty(data_to_load.(table_list{it}))
        switch table_list{it}
            case 't_transducer'
                if any(cellfun(@isempty,data_to_load.t_transducer.transducer_serial))
                    data_to_load=[];
                    warndlg_perso([],'Missing Serial Number','Misssing Transducer Serial number. Please complete.');
                    return;
                end
            case 't_transceiver'
                if any(cellfun(@isempty,data_to_load.t_transceiver.transceiver_serial))
                    data_to_load=[];
                    warndlg_perso([],'Missing Serial Number','Misssing Transceiver Serial number. Please complete.');
                    return;
                end
        end
    end
    
    
    % finding and recording the maximium pkey value for each table
    max_pkey = get_max_pkey_from_table(db_dest_conn,table_list{it},pkey_list{it});
    val_pkey_max.(table_list{it}) = max_pkey;
    
end

if ~isempty(data_to_load.t_navigation)
    data_to_load.t_navigation.navigation_depth(isnan(data_to_load.t_navigation.navigation_depth)) = 0;
end

fprintf('DONE.\n');


%% Transfer to new database and updates of pkeys in appropriate tables
fprintf('Loading contents of tables from source database/schema into destination database/schema...\n');
for it = 1:numel(table_list)
    
    fprintf('	Now doing table %s...\n',table_list{it});
    
    if isempty(data_to_load.(table_list{it}))
        fprintf('       No data in this table. Skip it.\n\n');
        new_pkey_val.(table_list{it}) = [];
        continue;
    end
    
    %% updating primary key in LOAD schema table
    if ~isnan(val_pkey_max.(table_list{it})) && it>6
        fprintf('       Updating primary key....\n');
        data_to_load.(table_list{it}).(pkey_list{it}) = data_to_load.(table_list{it}).(pkey_list{it}) + val_pkey_max.(table_list{it});
    else
        val_pkey_max.(table_list{it}) = 0;
    end
    
    %% updating foreign keys
    if ~isempty(fkey_list{it})
        
        fprintf('       Updating foreign key:\n');
        
        for ifkey = 1:numel(fkey_list{it})
            
            fkey = fkey_list{it}{ifkey}{1}; % foreign key in this table
            t_ref = fkey_list{it}{ifkey}{2}; % table whose pkey is being referenced
            pkey_t_ref = pkey_list{strcmp(t_ref,table_list)}; % name of pkey being referenced
            
            % exit if table being referenced is empty
            if isempty(data_to_load.(t_ref))
                continue;
            end
            
            % display
            fprintf('           "%s.%s" referencing pkey "%s.%s"...\n',table_list{it},fkey,t_ref,pkey_t_ref);
            
            % current foreign keys values in data_to_load
            data_f_key_ori = data_to_load.(table_list{it}).(fkey);
            
            % old primary keys in table being referenced
            old_pkeys = data_to_load.(t_ref).(pkey_t_ref) - val_pkey_max.(t_ref);
            
            % udpated primary keys in table being referenced
            new_pkeys = new_pkey_val.(t_ref);
            
            if numel(new_pkeys) == numel(old_pkeys)
                for ival = 1:length(new_pkeys)
                    % updating each foreign key value
                    data_to_load.(table_list{it}).(fkey)(data_f_key_ori==old_pkeys(ival)) = new_pkeys(ival);
                end
            else
                warning('transfer_ac_database:issue while inserting values, unicity problem...');
            end
            
        end
    end
    
    %% removing the contents we don't need to insert
    unique_fields = ukey_list{it};
    fields = fieldnames(data_to_load.(table_list{it}));
    idx_rem = ~ismember(fields,unique_fields);
    if any(idx_rem)
        fields_to_remove = fields(idx_rem);
        struct_in_minus_key = rmfield(data_to_load.(table_list{it}),fields_to_remove);
    else
        struct_in_minus_key = data_to_load.(table_list{it});
    end
    
    %% inserting new contents
    fprintf('       Inserting new table records in destination database/schema...\n');
    new_pkey_val.(table_list{it}) = insert_data_controlled(db_dest_conn,table_list{it},data_to_load.(table_list{it}),struct_in_minus_key,pkey_list{it});
    fprintf('\n');
    
    %% backup table contents in LOAD schema
    if p.Results.backup_and_remove_src>0
        try
            fprintf('       Backing-up this table in source database/schema...\n');
            sql_query_create = sprintf('CREATE TABLE %s_%06d (LIKE %s INCLUDING ALL)',table_list{it},load_id,table_list{it});
            sql_query_insert = sprintf('INSERT INTO %s_%06d SELECT * FROM %s',table_list{it},load_id,table_list{it});
            db_src_conn.exec(sql_query_create);
            db_src_conn.exec(sql_query_insert);
        catch err
            disp(err.message);
            warning('backup_and_remove_src:Error while executing sql query');
        end
    end
    
end

if p.Results.backup_and_remove_src>0
    try
        fprintf('Deleting contents of source database/schema...\n');
        sql_query_truncate = sprintf('TRUNCATE %s',strjoin(table_list,','));
        db_src_conn.exec(sql_query_truncate);
    catch err
        disp(err.message);
        warning('backup_and_remove_src:Error while executing sql query');
    end
end

%% disp
fprintf('Transfer done. For info, here are the missions and deployments now in the source database/schema:.\n')
disp(db_src_conn.fetch('SELECT * FROM t_mission'));
disp(db_src_conn.fetch('SELECT * FROM t_deployment'));
fprintf('And here are the missions and deployments now in the destination database/schema:.\n')
disp(db_dest_conn.fetch('SELECT * FROM t_mission'));
disp(db_dest_conn.fetch('SELECT * FROM t_deployment'));

%% close database connections
db_src_conn.close();
db_dest_conn.close();
