%% load_echo_logbook_db.m
%
% TODO: write short description of function
%
%% Help
%
% *USE*
%
% TODO: write longer description of function
%
% *INPUT VARIABLES*
%
% * |layers_obj|: TODO: write description and info on variable
%
% *OUTPUT VARIABLES*
%
% NA
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2017-04-02: header (Alex Schimel).
% * YYYY-MM-DD: first version (Yoann Ladroit). TODO: complete date and comment
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function load_echo_logbook_db(layers_obj)

incomplete=0;
[pathtofile,~]=layers_obj.get_path_files();
pathtofile=unique(pathtofile);

pathtofile(cellfun(@isempty,pathtofile))=[];

for ip=1:length(pathtofile)
    try
        fileN=fullfile(pathtofile{ip},'echo_logbook.db');
        
        if ~isfile(fileN)
            initialize_echo_logbook_dbfile(pathtofile{ip},[],0);
        end
        
        dbconn=sqlite(fileN,'connect');
        createlogbookTable(dbconn);
        createsurveyTable(dbconn);
        files_db=dbconn.fetch('select Filename from logbook');
        
        close(dbconn);
        [ac_files,~]=list_ac_files(pathtofile{ip},1);
        
        if ~isempty(setdiff(ac_files,files_db))
            incomplete=1;
            fprintf('%s incomplete, we''ll update it\n',fileN);
        end
        
    catch err
        print_errors_and_warnings([],'error',err);
    end
end

try
    if incomplete>0
        layers_obj.update_echo_logbook_dbfile();
    end
    layers_obj.add_survey_data_db(); 
catch err
    print_errors_and_warnings([],'error',err);
end