function export_NMEA_to_csv_callback(~,~,main_figure,IDs,filename_append)

% get all layers
layers = get_esp3_prop('layers');
if isempty(layers)
    return;
end

load_bar_comp = show_status_bar(main_figure,0);

% find layers to export
if ~iscell(IDs)
    IDs = {IDs};
end
if isempty(IDs{1})
    % empty IDs means do all layers
    layers_to_export = layers;
else
    % else, find the layers with input IDs
    idx = [];
    for id = 1:length(IDs)
        [idx_temp,found] = find_layer_idx(layers,IDs{id});
        if found == 0
            continue;
        end
        idx = union(idx,idx_temp);
    end
    layers_to_export = layers(idx);
end

% process per layer
for ilay = 1:length(layers_to_export)
    
    layer = layers_to_export(ilay);
    filenames = layer.Filename;
    
    % process per file in layer
    for ifil = 1:length(filenames)
        
        % input file info
        input_fullfile = filenames{ifil};
        [path_f,fileN,~] = fileparts(input_fullfile);
        
        try
            % get corresponding index file
            fileIdx = fullfile(path_f,'echoanalysisfiles',[fileN '_echoidx.mat']);
            if exist(fileIdx,'file') == 0
                % file has not been indexed yet, do it now
                idx_raw_obj = idx_from_raw_v2(input_fullfile,p.Results.load_bar_comp);
                save(fileIdx,'idx_raw_obj');
            else
                % file has already been indexed. Check and do it again (?)
                load(fileIdx);
                % get finish time in file
                [~,et] = start_end_time_from_file(input_fullfile);
                % get datagrams in file
                dgs = find( (strcmp(idx_raw_obj.type_dg,'RAW0')|strcmp(idx_raw_obj.type_dg,'RAW3')) & idx_raw_obj.chan_dg==nanmin(idx_raw_obj.chan_dg) );
                if et-idx_raw_obj.time_dg(dgs(end)) > 2*nanmax(diff(idx_raw_obj.time_dg(dgs)))
                    fprintf('Re-Indexing file: %s\n',input_fullfile);
                    delete(fileIdx);
                    idx_raw_obj = idx_from_raw_v2(input_fullfile,p.Results.load_bar_comp);
                    save(fileIdx,'idx_raw_obj');
                end
            end
            
            % get NMEA messages
            [~,~,NMEA,~] = data_from_raw_idx_cl_v7(path_f,idx_raw_obj,'GPSOnly',1,'load_bar_comp',load_bar_comp);
            
            % reformatting
            NMEA.time = cellfun(@(x) datestr(x,'dd/mm/yyyy HH:MM:SS'),(num2cell(NMEA.time')),'UniformOutput',0);
            NMEA.string = NMEA.string';
            
            % output file name
            output_fullfile = fullfile(path_f,[fileN,filename_append,'.csv']);
            
            ff=fieldnames(NMEA);
            
            for idi=1:numel(ff)
                if isrow(NMEA.(ff{idi}))
                    NMEA.(ff{idi})=NMEA.(ff{idi})';
                end
            end
            % export
            struct2csv(NMEA,output_fullfile);
            
            % display
            disp_perso(main_figure,sprintf('NMEA for file %s exported as %s',input_fullfile,output_fullfile));
            
            % open resulting file
            open_txt_file(output_fullfile);
            
        catch err
            print_errors_and_warnings([],'error',err);
            warndlg_perso(main_figure,'',sprintf('Could not export NMEA for file %s',input_fullfile));
        end
        
    end
    
end
