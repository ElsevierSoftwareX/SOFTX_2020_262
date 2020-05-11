function create_t_load(ac_db_filename)

if ischar(ac_db_filename)
    dbconn=connect_to_db(ac_db_filename);
else
    dbconn=ac_db_filename;
end

sql_query=['CREATE TABLE t_load ('...
    'load_pkey SERIAL PRIMARY KEY,'...
    'load_user text COLLATE pg_catalog."default",'...
    'load_time timestamp without time zone,'...
    'load_comments text COLLATE pg_catalog."default"'...
    ')'];

dbconn.exec(sql_query);



if ischar(ac_db_filename)
    dbconn.close();
end
