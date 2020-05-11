function [output_cols,output_vals,SQL_query] = get_cols_from_table(database_filename,SQL_table_name,varargin)

% this function is to get data from a table in a database through a
% standard "SELECT attribute FROM table WHERE condition" SQL query. 
%
% One must provide the database filename ("database_filename") and the table
% ("SQL_table_name") and the desired condition either in the form of matching
% attributes ("input_cols") and values ("input_vals"), or a Matlab
% structure matching the table of interest ("input_struct") and the index
% of the row with the values in that structure ("row_idx").


%% input parser
p = inputParser;
addRequired(p,'database_filename',@(x) ischar(x)||isa(x,'database.jdbc.connection'));
addRequired(p,'SQL_table_name',@ischar);
addParameter(p,'input_cols',{},@iscell);
addParameter(p,'input_vals',{},@iscell);
addParameter(p,'output_cols',{},@iscell);
addParameter(p,'input_struct',struct.empty(),@isstruct);
addParameter(p,'row_idx',[],@isnumeric);
parse(p,database_filename,SQL_table_name,varargin{:});


%% initialize results:
output_cols = p.Results.output_cols;
output_vals = [];


%% get the attributes and values needed to build the condition
if ~isempty(p.Results.input_cols) && ~isempty(p.Results.input_vals)
    
    % check they match
    if numel(p.Results.input_cols) ~= numel(p.Results.input_vals)
        disp('get_cols_from_table:Invalid number of column specified in inputs for SQL query');
        return;
    end
    
    % all good, go on
    input_vals = p.Results.input_vals;
    input_cols = p.Results.input_cols;
    
elseif ~isempty(p.Results.input_struct)
    % this is the alternative input: provided a Matlab structure matching
    % the table of interest ("input_struct") and the index of the row with
    % the values in that structure ("row_idx"). Build input_cols and
    % input_vals from them
    
    % initialize
    input_cols = fieldnames(p.Results.input_struct);
    input_vals = cell(1,numel(input_cols));
    
    % grabbing data in input_struct for desired rows (row_idx), for each
    % attribute
    for iin = 1:numel(input_cols)
        
        if ~isempty(p.Results.row_idx)
            % in case, a row index was given in input
            
            % recording value depending on its format
            if iscell(p.Results.input_struct.(input_cols{iin}))
                input_vals{iin} = p.Results.input_struct.(input_cols{iin})(p.Results.row_idx);
            else
                if ischar(p.Results.input_struct.(input_cols{iin})(p.Results.row_idx))
                    input_vals{iin} = {p.Results.input_struct.(input_cols{iin})};
                else
                    input_vals{iin} = p.Results.input_struct.(input_cols{iin})(p.Results.row_idx);
                end
            end
            
        else
            % if no row index was given, take them all
            if ischar(p.Results.input_struct.(input_cols{iin}))
                input_vals{iin} = {p.Results.input_struct.(input_cols{iin})};
            else
                input_vals{iin} = p.Results.input_struct.(input_cols{iin});
            end
            
        end
    end
    
else
    
    disp('get_cols_from_table: Invalid inputs');
    return;
    
end

%% with the matching attributes and values pair, build the condition part of the SQL query

% number of entries
nb_vals = cellfun(@numel,input_vals);
nb_comb = max(nb_vals);

% initialize final condition
input_tot = cell(1,nb_comb);

for i_comb = 1:nb_comb
    
    % (re)-initialize the cell arrays of attribute=value strings
    inputs_cell = cell(1,numel(input_cols));
    
    % filling it in
    for i_in = 1:numel(input_cols)
        if ~isempty(input_vals{i_in})
            if ischar(input_vals{i_in})
                input_vals{i_in} = strrep(input_vals{i_in},'''','''''');
                inputs_cell{i_in} = sprintf('%s = ''%s''',input_cols{i_in},input_vals{i_in});
            elseif iscell(input_vals{i_in})
                if ~isnan(input_vals{i_in}{i_comb})
                    if isnumeric(input_vals{i_in}{i_comb})
                        inputs_cell{i_in} = sprintf('%s = %f',input_cols{i_in},input_vals{i_in}{i_comb});
                    else
                        input_vals{i_in}{i_comb} = strrep(input_vals{i_in}{i_comb},'''','''''');
                        inputs_cell{i_in} = sprintf('%s = ''%s''',input_cols{i_in},input_vals{i_in}{i_comb});
                    end
                end
            elseif isnumeric(input_vals{i_in})
                if ~isnan(input_vals{i_in}(i_comb))
                    inputs_cell{i_in} = sprintf('%s = %f',input_cols{i_in},input_vals{i_in}(i_comb));
                end
            end
        end
    end
    
    % removing empty bits
    inputs_cell(cellfun(@isempty,inputs_cell)) = [];
    
    % building the condition string
    input_tot{i_comb} = strjoin(inputs_cell,' AND ');
    
end

% removing empty bits
input_tot(cellfun(@isempty,input_tot)) = [];

% and building the condition
if ~isempty(input_tot)
    SQL_condition = strjoin(input_tot,') OR (');
else
    SQL_condition = [];
end


%% building the SQL part for attributes queried
if ~isempty(output_cols)
    SQL_attribute = strjoin(output_cols,',');
else
    SQL_attribute = '*';
end


%% Putting together the SQL query
try
    
    % connect to database
    if ischar(database_filename)
        dbconn = connect_to_db(database_filename);
    else
        dbconn = database_filename;
    end
    
    % build the full query from parts
    if ~isempty(SQL_condition)
        SQL_query = sprintf('SELECT %s FROM %s WHERE (%s)', SQL_attribute, SQL_table_name, SQL_condition);
    else
        SQL_query = sprintf('SELECT %s FROM %s',SQL_attribute, SQL_table_name);
    end
    
    % execute the SQL query to get data
    output_vals = dbconn.fetch(SQL_query);
    
    % close the database
    if ischar(database_filename)
        dbconn.close();
    end
    
catch err
    disp(err.message);
    warning('get_cols_from_table: Error while connecting to db file, building query, executing query, or closing db');
end


%
% inputs_cell=cell(1,numel(input_cols));
%
% idx_keep=cellfun(@(x) ~isempty(x),input_vals);
%
% if any(idx_keep)
%     input_statement_start=sprintf('(%s) IN',strjoin(input_cols,','));
%
%     for i_in=1:numel(input_cols)
%         if ~isempty(input_vals{i_in})
%             if ischar(input_vals{i_in})
%                 inputs_cell{i_in}=sprintf('(%s)',input_vals{i_in});
%             elseif iscell(input_vals{i_in})
%                 inputs_cell{i_in}=sprintf('("%s")',strjoin(input_vals{i_in},'","'));
%             elseif isnumeric(input_vals{i_in})
%                 inputs_cell{i_in}=sprintf('(%s)',input_cols{i_in},strjoin(cellfun(@num2str,num2cell(input_vals{i_in}),'un',0),','));
%             end
%         end
%     end
% else
%     input_statement_start='';
% end
%
% inputs_cell(cellfun(@isempty,inputs_cell))=[];
%
% if ~isempty(p.Results.output_cols)
%     SQL_attribute=strjoin(p.Results.output_cols,',');
% else
%     SQL_attribute='*';
% end
%
% try
%     dbconn=connect_to_db(database_filename);
%     if ~isempty(inputs_cell)
%         SQL_query=sprintf('SELECT %s FROM %s WHERE %s IN (%s)',SQL_attribute,p.Results.table_name,input_statement_start,strjoin(inputs_cell,','));
%     else
%         SQL_query=sprintf('SELECT %s FROM %s',SQL_attribute,table_name);
%     end
%     output_vals=dbconn.fetch(SQL_query);
%     dbconn.close();
% catch err
%     disp(err.message);
%     warning('get_cols_from_table:Error while executing sql query');
% end