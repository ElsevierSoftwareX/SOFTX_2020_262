
function add_ping_data_to_db(layers_obj,itrans_tot,clear_existing_data)

for ilay=1:length(layers_obj)
    if isempty(itrans_tot)
        itrans_tot=1:numel(layers_obj(ilay).Transceivers);
    end
    
    for itrans=itrans_tot
        try
            
            trans_obj=layers_obj(ilay).Transceivers(itrans);
            freq=layers_obj(ilay).Frequencies(itrans);
            
            %[~,filename_cell]=fileparts_cell(layers_obj(ilay).Filename);
            
            gps_data=get_ping_data_from_db(layers_obj(ilay).Filename,freq);
            gps_data_obj=trans_obj.GPSDataPing;
            
            if isempty(gps_data_obj)||all(gps_data_obj.Lat==0)
                continue;
            end
            
            if ~isempty(gps_data{end})
                if abs(gps_data_obj.Time(end)-gps_data{end}.Time(end))<5/(24*60*60)&&abs(gps_data_obj.Time(1)-gps_data{end}.Time(1))<5/(24*60*60)&&~clear_existing_data>0
                    if~isdeployed()
                        fprintf('Gps data up to date\n');
                    end
                    continue;
                end
            end
            
            fileID_vec=trans_obj.get_fileID();
            
            
            bot_range=trans_obj.get_bottom_range();
            
            [~,id_keep]=gps_data_obj.clean_gps_track();
            id_keep=intersect(id_keep,find(~isnan(gps_data_obj.Lat)));
            if numel(numel(id_keep))==0
                continue;
            end
            if~isdeployed()
                fprintf('Number of pings: %.0f\nReduced Number of point in navigation:%.0f\n',numel(gps_data_obj.Time),numel(id_keep))	;
            end
            
            
            for ip=1:length(layers_obj(ilay).Filename)
                idx_pings=find(fileID_vec==ip);
                if ~(isempty(gps_data{ip})||clear_existing_data>0)
                    if gps_data_obj.Time(end)<=gps_data{ip}.Time(end)
                        continue;
                    end
                end
               
                id_keep_f=intersect(id_keep,idx_pings);
                if isempty(id_keep_f)        
                   continue;
                end
                [pathtofile,fileOri,extN]=fileparts(layers_obj(ilay).Filename{ip});
                
                fileN=fullfile(pathtofile,'echo_logbook.db');
                
                if exist(fileN,'file')==0
                    initialize_echo_logbook_dbfile(pathtofile,[],0);
                end
                
                if ~any(gps_data_obj.Lat~=0)
                    continue;
                end
                
                dbconn=sqlite(fileN,'connect');
                createPingTable(dbconn);
                dbconn.exec(sprintf('delete from ping_data where Filename is "%s"',[fileOri extN]));
                if clear_existing_data>0
                    clearPingTable(dbconn,[fileOri extN],freq);
                end
                
                time_cell=cellfun(@(x) datestr(x,'yyyy-mm-dd HH:MM:SS'),(num2cell(gps_data_obj.Time(id_keep_f))),'UniformOutput',0);
                colnames={'Filename' 'Ping_number' 'Frequency' 'Lat' 'Long' 'Time' 'Depth'};
                try
                    t=table(...
                        repmat({[fileOri extN]},numel(id_keep_f),1),...
                        id_keep_f'-idx_pings(1)+1,...
                        repmat(freq,numel(id_keep_f),1),...
                        gps_data_obj.Lat(id_keep_f)',...
                        gps_data_obj.Long(id_keep_f)',...
                        time_cell',...
                        bot_range(id_keep_f)',...
                        'VariableNames',colnames);
                    dbconn.insert('ping_data',colnames,t);
                catch err
                    print_errors_and_warnings([],'error',err);
                end
                
                

                
                close(dbconn);
                
            end
            
        catch err
            print_errors_and_warnings([],'error',err);
        end
    end
    
end


% dbconn=connect_to_db(fileN);
% dbconn.exec();
% dbconn.exec('SELECT InitSpatialMetaData(1);');
% dbconn.exec('SELECT addgeometrycolumn(''ping_data'',''nav_geom'',4326,''POINT'',''XY'')');
% 
% dbconn.exec('UPDATE ping_data SET nav_geom = MakePoint(Long,Lat,4326);');
% dbconn.close();

end


