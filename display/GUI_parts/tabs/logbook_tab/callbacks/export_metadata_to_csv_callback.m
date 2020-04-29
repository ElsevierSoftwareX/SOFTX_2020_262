function export_metadata_to_csv_callback(~,~,main_figure,path_f)

if isempty(path_f)
    layer = get_current_layer();
    
    if isempty(layer)
        return;
    end
    [path_lay,~] = layer.get_path_files();
    path_f=path_lay{1};    
end


surv_data_struct = get_struct_from_db(path_f);

if isempty(surv_data_struct)
    return;
end

struct_out = struct('Filename','','Snapshot',0,'Type','','Stratum','','Transect',0,'StartTime',0,'EndTime',1,'StartLat',0,'EndLat',0,'StartLong',0,'EndLong',0,'Comment','');
field_csv = fieldnames(struct_out);

for ifs = 1:length(field_csv)
    if isfield(surv_data_struct,field_csv{ifs})
        struct_out.(field_csv{ifs}) = surv_data_struct.(field_csv{ifs});
    end
end

struct_out.StartLat = zeros(size(struct_out.Stratum));
struct_out.StartLong = zeros(size(struct_out.Stratum));
struct_out.EndLat = zeros(size(struct_out.Stratum));
struct_out.EndLong = zeros(size(struct_out.Stratum));

for i = 1:length(struct_out.Stratum)
    [struct_out.StartLat(i),struct_out.EndLat(i),struct_out.StartLong(i),struct_out.EndLong(i)] = start_end_lat_long_from_raw_file(fullfile(path_f,struct_out.Filename{i}));
end

str_fname=generate_valid_filename([surv_data_struct.Voyage{1} '_' surv_data_struct.SurveyName{1} '_metadata.csv']);

[filename, pathname] = uiputfile('*.csv',...
    'Save survey csv Metadata file',...
    fullfile(path_f,str_fname));

if isequal(filename,0) || isequal(pathname,0)
    return;
end
T = struct2table(struct_out);

writetable(T,fullfile(pathname,filename));

end