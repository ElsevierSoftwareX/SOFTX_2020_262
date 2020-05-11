function  index_files_callback(~,~,main_figure)
layer=get_current_layer();

if ~isempty(layer)
    [path_lay,~]=get_path_files(layer);
    if ~isempty(path_lay)
        file_path=path_lay{1};
    else
        file_path=pwd;
    end
else
    file_path=pwd;
end

Filename=get_compatible_ac_files(file_path);

if isempty(Filename)||isequal(Filename,0)
    return;
end

show_status_bar(main_figure);
load_bar_comp=getappdata(main_figure,'Loading_bar');
str_disp='Indexing Files';
if ~isempty(load_bar_comp)
    set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',length(Filename), 'Value',0);
    load_bar_comp.progress_bar.setText(str_disp);
else
    disp(str_disp);
end
for i=1:length(Filename)
    if ~isempty(load_bar_comp)
        set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',length(Filename), 'Value',i);
    end
    fileN=Filename{i};
    [PathToFile,fname,ext]=fileparts(Filename{i});
    if ~strcmpi(ext,'.raw')
        continue;
    end
    
    if ~isfolder(fullfile(PathToFile,'echoanalysisfiles'))
        mkdir(fullfile(PathToFile,'echoanalysisfiles'));
    end
    fileIdx=fullfile(PathToFile,'echoanalysisfiles',[fname '_echoidx.mat']);
    
    
    if exist(fileIdx,'file')==0
        idx_raw_obj=idx_from_raw_v2(fileN,load_bar_comp);
        save(fileIdx,'idx_raw_obj');
    else
        load(fileIdx);
        [~,et]=start_end_time_from_file(fileN);
        dgs=find((strcmp(idx_raw_obj.type_dg,'RAW0')|strcmp(idx_raw_obj.type_dg,'RAW3'))&idx_raw_obj.chan_dg==nanmin(idx_raw_obj.chan_dg));
        if et-idx_raw_obj.time_dg(dgs(end))>2*nanmax(diff(idx_raw_obj.time_dg(dgs)))
            fprintf('Re-Indexing file: %s\n',Filename{i});
            delete(fileIdx);
            idx_raw_obj=idx_from_raw_v2(fileN,load_bar_comp);
            save(fileIdx,'idx_raw_obj');
        end
    end
    
    if exist(fileIdx,'file')>0
       delete(fileIdx); 
    end
    
    save(fileIdx,'idx_raw_obj');

end
hide_status_bar(main_figure);



