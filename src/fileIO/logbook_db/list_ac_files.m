%% list_ac_file_db.m
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
% * |input_variable_1|: TODO: write description and info on variable
%
% *OUTPUT VARIABLES*
%
% * |output_variable_1|: TODO: write description and info on variable
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2017-05-17: first version (Yoann Ladroit). TODO: complete date and comment
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function

function [files,ftype]=list_ac_files(datapath,listonly)

% dir_raw=dir(fullfile(datapath,'*.raw'));
% dir_asl=dir(fullfile(datapath,'*.*A'));
% dir_ini=dir(fullfile(datapath,'*.ini'));
% 
% list_files=[dir_raw(:);dir_asl(:);dir_ini(:)];
% list_files([list_files(:).isdir])=[];
% [~,idx_sort]=sort([list_files(:).datenum]);
% 
% files={list_files(idx_sort).name};

list_files = dir(datapath);

% [~,idx]=sort([list_files(:).datenum]);
% list_files=list_files(idx);

list_files([list_files(:).isdir])=[];

[~,idx_keep]= filter_ac_files({list_files.name});

list_files=list_files(idx_keep);

files={list_files.name};

ftype=cell(1,numel(files));

if listonly==0
    for ifi=1:numel(files)
        ftype{ifi}=get_ftype(fullfile(datapath,files{ifi}));
    end
    
    idx_rem=strcmpi('unknown',ftype);
    ftype(idx_rem)=[];
end

end



