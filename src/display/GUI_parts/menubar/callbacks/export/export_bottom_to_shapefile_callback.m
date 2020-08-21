function export_bottom_to_shapefile_callback(~,~,main_figure,IDs)

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
output_fullfile = fullfile(path_lay{1},'bottom_data.shp');
[filename, pathname] = uiputfile('*.shp','Export bottom data to shapefile',output_fullfile);
if isequal(filename,0) || isequal(pathname,0)
    % cancel
    return;
end
output_fullfile = fullfile(pathname,filename);

% initialize file counter
clear Points
iPoints = 0;

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
        
        % get data
        Time       = gps_obj.Time(idx_ping);
        Lat        = gps_obj.Lat(idx_ping);
        Lon        = gps_obj.Long(idx_ping);
        Depth      = get_bottom_depth(trans_obj,idx_ping);
        BadPingTag = get_badtrans_tag(trans_obj,idx_ping);
        [E1,E2]    = get_bottom_features(trans_obj,idx_ping);
        
        % some processing
        Depth(BadPingTag==0) = NaN;
        E1(BadPingTag==0 | E1==-999) = NaN;
        E2(BadPingTag==0 | E2==-999) = NaN;
        
        % figure; plot(E1); title(file_name);
        
        window_size = nanmin(numel(idx_ping)/2,500); % in pings
        
        Time = movmedian(Time,window_size,'omitnan');
        Time = Time(ceil(window_size./2):window_size:end);
        
        Date = datestr(Time);
        
        Lat = movmedian(Lat,window_size,'omitnan');
        Lat = Lat(ceil(window_size./2):window_size:end);
        
        Lon = medfilt1(Lon,window_size,'omitnan');
        Lon = Lon(ceil(window_size./2):window_size:end);
        
        Depth = medfilt1(Depth,window_size,'omitnan');
        Depth = Depth(ceil(window_size./2):window_size:end);
        
        E1 = medfilt1(E1,window_size,'omitnan');
        E1 = E1(ceil(window_size./2):window_size:end);
        
        E2 = medfilt1(E2,window_size,'omitnan');
        E2 = E2(ceil(window_size./2):window_size:end);
        
        Geometry   = repmat('Point',[numel(Lat),1]);
        Filename   = repmat([file_name filt_ext],[numel(Lat),1]);
        
        
        T = table(Geometry, Filename, Date, Lat', Lon', Depth', E1', E2',...
            'VariableNames',{'Geometry' 'Filename' 'Date' 'Lat' 'Lon' 'Depth' 'E1' 'E2'});

        iPoints = iPoints+1;
        Points{iPoints} = table2struct(T);

    end
end

% combine
PointsTable = vertcat(Points{:});

% some display
% f1 = figure(); 
% geobubble([PointsTable.Lat],[PointsTable.Lon],exp([PointsTable.E1]));
% title('log(E1) ("roughness")')
% 
% f2 = figure(); 
% geobubble([PointsTable.Lat],[PointsTable.Lon],exp([PointsTable.E2]));
% title('log(E2) ("hardness")')
% 
% f3 = figure(); 
% subplot(221); plot([PointsTable.E1],[PointsTable.E2],'k.'); grid on
% xlabel('E1');ylabel('E2')
% subplot(222); plot([PointsTable.Depth],[PointsTable.E1],'b.');grid on
% xlabel('Depth');ylabel('E1')
% subplot(223); plot([PointsTable.Depth],[PointsTable.E2],'r.');grid on
% xlabel('Depth');ylabel('E2')

% export
shapewrite(PointsTable,output_fullfile);

% display
disp_perso(main_figure,sprintf('Bottom for all files exported as %s',output_fullfile));
