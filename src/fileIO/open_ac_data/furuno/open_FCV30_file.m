function new_layers=open_FCV30_file(file_lst_cell,varargin)

p = inputParser;

[def_path_m,~,~]=fileparts(file_lst_cell);

addRequired(p,'file_lst',@(x) iscell(x)||ischar(x));
addParameter(p,'PathToMemmap',def_path_m,@ischar);
addParameter(p,'load_bar_comp',[]);

parse(p,file_lst_cell,varargin{:});

if ~iscell(file_lst_cell)
    file_lst_cell={file_lst_cell};
end

for ic=1:numel(file_lst_cell)
    
    file_lst=file_lst_cell{ic};
    [~,~,ext]=fileparts(file_lst);
    switch ext
        case '.lst'
            list_files=importdata(file_lst);
            filename_ini=cell(1,length(list_files));
            
            for i=1:length(list_files)
                str_temp=strsplit(list_files{i},',');
                filename_ini{i}=str_temp{2};
            end
            filename_ini=unique(filename_ini);
            
            [fidx,val] = listdlg_perso([],'Choose Files to open',filename_ini,'timeout',10);
            if val==0
                new_layers=[];
                return;
            end
        case '.ini'
            fidx=[];
    end
    try
        new_layers=open_FCV30_file_stdalone_v2(file_lst,...
            'PathToMemmap',p.Results.PathToMemmap,'load_bar_comp',p.Results.load_bar_comp,'file_idx',fidx);
        
    catch err
        warndlg_perso([],'',sprintf('Could not open files %s\n',file_lst));
        print_errors_and_warnings(1,'error',err);
        %             if ~isdeployed
        %                 rethrow(err);
        %             end
    end
end