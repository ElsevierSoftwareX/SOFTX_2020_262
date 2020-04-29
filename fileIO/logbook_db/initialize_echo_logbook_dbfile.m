function initialize_echo_logbook_dbfile(datapath,main_figure,force_create)

[list_raw,ftypes]=list_ac_files(datapath,0);

db_file=fullfile(datapath,'echo_logbook.db');
if isfile(db_file)
    return;
end

xml_file=fullfile(datapath,'echo_logbook.xml');
if isfile(xml_file)&&force_create==0
    xml_logbook_to_db(xml_file);
    return;
end

csv_file='echo_logbook.csv';
if isfile(csv_file)&&force_create==0
    csv_logbook_to_db(datapath,csv_file,'','');
    return;
end

if isfile(db_file)
    delete(db_file);
end

disp_perso(main_figure,'Creating .db logbook file, this might take a couple minutes...');
%try
    %     sqlite_folder=fullfile(whereisEcho(),'ext_lib');
    %     strrep(sqlite_folder,' ','\');
    %     path_cmd=sprintf('setx PATH "%%PATH%%;%s"',sqlite_folder);
    %
    %     [stat,out]=system(path_cmd,'-echo');
    %
    %     sqlite_cmd=sprintf('SELECT load_extension(%s);','''mod_spatialite.dll''');
    %     final_cmd=sprintf('sqlite3 "%s" "%s"&',db_file,sqlite_cmd);
    %     [stat,out]=system(final_cmd,'-echo');
    %
    %     sqlite_cmd='SELECT InitSpatialMetadata(1);';
    %     final_cmd=sprintf('sqlite3 "%s" "%s"',db_file,sqlite_cmd);
    %     [stat,out]=system(final_cmd,'-echo');
    %     dbconn=sqlite(db_file,'connect');
%catch
    
%end

dbconn=sqlite(db_file,'create');

createlogbookTable(dbconn);
createsurveyTable(dbconn);
createPingTable(dbconn);
%creategpsTable(dbconn);

dbconn.insert('survey',{'SurveyName' 'Voyage' },{'' ''});

if force_create==0
    add_files_to_db(datapath,list_raw,ftypes,dbconn,[])
end
close(dbconn);





end