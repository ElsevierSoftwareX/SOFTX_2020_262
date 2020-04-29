function  plot_gps_track_from_filenames(main_figure,Filename,disp,f_save)

%% open all files (GPS only)

if isempty(Filename)
    return;
end
% status bar
show_status_bar(main_figure);
try
    [new_layers,idx_empty] = create_gps_layers_from_db(Filename);
    
    if ~isempty(Filename(idx_empty))
        [new_layers_tmp,~]=open_file_standalone(Filename(idx_empty),'','GPSOnly',1);
        idx_keep=arrayfun(@(x) ~isempty(x.GPSData.Lat),new_layers_tmp);
        new_layers=[new_layers new_layers_tmp(idx_keep)];
    end
    
    if isempty(new_layers)
        warndlg_perso(main_figure,'','No position data for those files')
        return;
    end
    curr_disp=get_esp3_prop('curr_disp');
    
    %% display GPS
    
    new_layers.load_echo_logbook_db();
    
    if disp>0
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
    end
    
    if ~isempty(f_save)
        if isfile(f_save)
            delete(f_save);
        end
        [~,~,ext_output]=fileparts(f_save);
        
        for ilay=1:numel(new_layers)
            [~,filename,ext] = fileparts(new_layers(ilay).Filename{1});
            switch ext_output
                case '.csv'
                    time=new_layers(ilay).GPSData.Time;
                    output.file = repmat({[filename ext]},[numel(time) 1]);
                    output.time = cellfun(@(x) datestr(x,'dd/mm/yyyy HH:MM:SS.FFF'),num2cell(time),'UniformOutput',0);
                    output.lat  = new_layers(ilay).GPSData.Lat;
                    output.long = new_layers(ilay).GPSData.Long;
                    
                    ff=fieldnames(output);
                    
                    for idi=1:numel(ff)
                        if isrow(output.(ff{idi}))
                            output.(ff{idi})=output.(ff{idi})';
                        end
                    end
                    
                    % write (append) structure to file
                    struct2csv(output,f_save,0,'a');
                    clear output
                case '.shp'
                    field=genvarname(filename);
                    Lines.(field)=new_layers(ilay).GPSData.gps_to_geostruct([]);
                    Lines.(field).Filename=[filename ext];
            end
        end
    end
    
    if ~isempty(f_save)
        switch ext_output
            case '.shp'
                LineIDs = fieldnames(Lines);
                i = 1;
                for LineIndex = 1:numel(LineIDs)
                    
                    LineID = LineIDs{LineIndex};
                    Line = Lines.(LineID);
                    
                    if i==1
                        LinesArray = repmat(Line, numel(LineIDs), 1 );
                    else
                        LinesArray(i) = Line;
                    end
                    i = i + 1;
                end
                
                shapewrite(LinesArray,f_save);
        end
    end
    
catch err
    print_errors_and_warnings(1,'error',err);
end
hide_status_bar(main_figure);

end
