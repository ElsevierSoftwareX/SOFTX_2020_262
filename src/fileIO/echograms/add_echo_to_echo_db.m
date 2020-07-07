function  add_echo_to_echo_db(echo_db_file,echo_file,fname_cell,cid,freq)

if ~isfile(echo_db_file)
    dbconn=sqlite(echo_db_file,'create');
else
    dbconn=sqlite(echo_db_file,'connect');
end
createEchoTable(dbconn);

[data_path_cell,f_name_cell,ext_cell] = cellfun(@fileparts,fname_cell,'un',0);
f_name_cell = cellfun(@(x,y) [x y],f_name_cell,ext_cell,'un',0);

for uif = 1:numel(f_name_cell)
        dbconn.insert('echotable',{'EchoFile' 'DataPath' 'DataFile' 'ChannelID' 'Frequency'},...
            {echo_file data_path_cell{uif} f_name_cell{uif} cid freq});   
end

end


function createEchoTable(dbconn)

echo_table=dbconn.fetch('SELECT name FROM sqlite_master WHERE type=''table'' AND name=''echotable''');

if isempty(echo_table)
    createlogbookTable_str = ['CREATE TABLE echotable ' ...
        '(EchoFile VARCHAR DEFAULT NULL,'...
        'DataPath VARCHAR DEFAULT NULL,'...
        'DataFile VARCHAR DEFAULT NULL,'...
        'ChannelID VARCHAR DEFAULT NULL,'...
        'Frequency NUMERIC DEFAULT 38000,'...
        'Comment TEXT DEFAULT NULL,'...
        'PRIMARY KEY(EchoFile,DataPath,DataFile,Frequency) ON CONFLICT REPLACE)'];
    dbconn.exec(createlogbookTable_str);
end
end