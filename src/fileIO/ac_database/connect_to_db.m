function [dbconn,db_type]=connect_to_db(ac_db_filename,varargin)

p = inputParser;

addRequired(p,'ac_db_filename',@ischar);
addParameter(p,'db_type','',@ischar);
addParameter(p,'user',getenv('USERNAME'),@ischar);
addParameter(p,'pwd',getenv('USERNAME'),@ischar);
parse(p,ac_db_filename,varargin{:});

dbconn=[];


if isempty(p.Results.db_type)
    if isfile(ac_db_filename)||isfolder(ac_db_filename)
        db_type='SQlite';
        if isfolder(ac_db_filename)
            ac_db_filename=fullfile(ac_db_filename,'echo_logbook.db');
        end
    else
        db_type='PostgreSQL';
    end
else
    db_type=p.Results.db_type;
end


switch db_type
    case 'SQlite'
        try
            if ~isfile(ac_db_filename)
                return;
            end
            % Open the DB file
            % jdbc = org.sqlite.JDBC;
            % props = java.util.Properties;
            % dbconn = jdbc.createConnection(['jdbc:sqlite:' ac_db_filename],props);  % org.sqlite.SQLiteConnection object
            % Open the DB file
            
            user = '';
            password = '';
            driver = 'org.sqlite.JDBC';
            protocol = 'jdbc';
            subprotocol = 'sqlite';
            resource = ac_db_filename;
            url = strjoin({protocol, subprotocol, resource}, ':');
            dbconn = database(ac_db_filename, user, password, driver, url);
            if ~isempty(dbconn.Message)
                if contains(dbconn.Message,'ERROR')||contains(dbconn.Message,'No suitable driver')||contains(dbconn.Message,'The database has been closed')
                    error(dbconn.Message);
                end
            end
        catch err
            
            warning('connect_to_db:cannot use Sqlite JDBC driver! Some functions might not work...');
            print_errors_and_warnings(1,'error',err);
            if isfile(ac_db_filename)
                dbconn=sqlite(ac_db_filename,'connect');
            else
                dbconn=[];
                db_type='';
            end
        end
    case 'PostgreSQL'
        try
            conn=strsplit(ac_db_filename,':');
            dbconn = database(conn{2},p.Results.user,p.Results.pwd, ...
                'Vendor','PostgreSQL', ...
                'Server',conn{1});
            if ~isempty(dbconn.Message)
                if any(cellfun(@(x) contains(lower(dbconn.Message),x),{'failed','fatal','error'}))
                    dbconn=[];
                    db_type='';
                end
            end
            sql_query=sprintf('SET search_path = %s',conn{3});
            dbconn.exec(sql_query);
           
        catch
            dbconn=[];
            db_type='';
        end
        
end


