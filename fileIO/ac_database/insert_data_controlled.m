function pkey=insert_data_controlled(ac_db_filename,tablename,struct_in,struct_in_minus_key,pkey_name)

if isfield(struct_in_minus_key,pkey_name)
    struct_in_minus_key = rmfield(struct_in_minus_key,pkey_name);
end

bs = 1e3;

fields = fieldnames(struct_in);

for irow = 1:bs:numel(struct_in.(fields{1}))
    
    idx_ite = irow:min(irow+bs-1,numel(struct_in.(fields{1})));
    
    % this part reads strange. We're currently trying to insert the data
    % and in case any fails, we check if the records don't already exist,
    % remove those that already exist, and try to load again the remainer.
    % Why don't we do that check and remove the duplicates BEFORE trying to
    % insert them?  
    % --> Because looking for duplicates takes a long time, so I have taken the
    % try/fail approach, which succed mosts of the time, and takes a bit of
    % time when it fails :) (Yoann)
    try
        %tic
        datainsert_perso(ac_db_filename,tablename,struct_in,'idx_insert',idx_ite);
        %toc
        
%         tic
%         if ischar(ac_db_filename)
%             dbconn = connect_to_db(ac_db_filename);
%         else
%             dbconn = ac_db_filename;
%         end
%         T=struct2table(struct_in);
%         dbconn.sqlwrite(tablename,T);
%         
%         if ischar(ac_db_filename)
%              dbconn.close();
%         end
%         toc
    catch
        
        p_key = nan(numel(idx_ite),1);
        
        for i = 1:numel(idx_ite)
            
            [~,tmp] = get_cols_from_table(ac_db_filename,tablename,'input_struct',struct_in_minus_key,'output_cols',{pkey_name},'row_idx',idx_ite(i));
            
            if ~isempty(tmp)
                p_key(i) = tmp{1,1};
            end
            
        end
        
        idx_insert = idx_ite(isnan(p_key));
        
        if ~isempty(idx_insert)
            datainsert_perso(ac_db_filename,tablename,struct_in,'idx_insert',idx_insert);
        else
            fprintf('       All records in source table already exist in destination table. No new data were inserted.\n');
        end
        
    end
    
end

pkey = [];

for irow = 1:bs:numel(struct_in.(fields{1}))
    idx_ite = irow:min(irow+bs-1,numel(struct_in.(fields{1})));
    [~,tmp] = get_cols_from_table(ac_db_filename,tablename,'input_struct',struct_in_minus_key,'output_cols',{pkey_name},'row_idx',idx_ite);
    if~isempty(tmp)
        pkey = [pkey;tmp];
    end
end

if iscell(pkey)
    pkey = cell2mat(pkey);
end

if istable(pkey)
    pkey = table2struct(pkey,'ToScalar',true);
end

if isstruct(pkey)
    pkey = pkey.(pkey_name);
end


end