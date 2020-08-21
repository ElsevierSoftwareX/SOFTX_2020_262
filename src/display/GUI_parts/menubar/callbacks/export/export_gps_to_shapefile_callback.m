function export_gps_to_shapefile_callback(~,~,main_figure,IDs)

% get current layers
layers = get_esp3_prop('layers');
if isempty(layers)
    return;
end

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

% output file name
[path_lay,~] = layers_to_export.get_path_files();
output_fullfile = fullfile(path_lay{1},'gps_data.shp');
[filename, pathname] = uiputfile('*.shp','Export GPS data to shapefile',output_fullfile);
if isequal(filename,0) || isequal(pathname,0)
    % cancel
    return;
end
output_fullfile = fullfile(pathname,filename);

% process per layer
for ilay = 1:length(layers_to_export)
    
    layer = layers_to_export(ilay);
    trans_obj = layer.Transceivers(1);
    gps_obj = trans_obj.GPSDataPing;
    filenames = layer.Filename;
    
    % process per file in layer
    for ifil = 1:length(filenames)
        
        [~,file_name,filt_ext] = fileparts(filenames{ifil});
        
        % get index of pings in dataset from this file
        idx_ping = find(trans_obj.Data.FileId==ifil);
        
        % create geostructs
        field = genvarname(file_name);
        Lines.(field) = gps_obj.gps_to_geostruct(idx_ping);
        Lines.(field).Filename = [file_name filt_ext];
        
    end
end

% get IDs for geostructs
LineIDs = fieldnames(Lines);

% create lines table
i = 1;
for lines_idx = 1:numel(LineIDs)
    
    LineID = LineIDs{lines_idx};
    Line = Lines.(LineID);
    
    if i==1
        LinesTable = repmat(Line, numel(LineIDs), 1 );
    else
        LinesTable(i) = Line;
    end
    i = i+1;
end

% export
shapewrite(LinesTable,output_fullfile);

% display
disp_perso(main_figure,sprintf('Position for all files exported as %s',output_fullfile));
