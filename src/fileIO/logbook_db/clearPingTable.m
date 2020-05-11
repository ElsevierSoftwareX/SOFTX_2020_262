function clearPingTable(dbconn,filename,freq)
    if isempty(freq)&&~isempty(filename)
        sql_cmd=sprintf('DELETE FROM ping_data WHERE filename=''%s'';',filename);
    elseif ~isempty(freq)&&isempty(filename)
        sql_cmd=sprintf('DELETE FROM ping_data WHERE frequency =%d;',freq);
    elseif isempty(freq)&&isempty(filename)
    	 sql_cmd=sprintf('DELETE FROM ping_data;');
    else
        sql_cmd=sprintf('DELETE FROM ping_data WHERE filename=''%s'' AND frequency =%d;',filename,freq);
    end
    dbconn.exec(sql_cmd);  
end