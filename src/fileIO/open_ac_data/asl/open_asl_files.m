function new_layers=open_asl_files(Filename,varargin)

p = inputParser;

if ~iscell(Filename)
    Filename={Filename};
end

if isempty(Filename)
    new_layers=[];
    return;
end

[def_path_m,~,~]=fileparts(Filename{1});

addRequired(p,'Filename',@(x) ischar(x)||iscell(x));
addParameter(p,'PathToMemmap',def_path_m,@ischar);
addParameter(p,'Frequencies',[],@isnumeric);
addParameter(p,'load_bar_comp',[]);
addParameter(p,'force_open',0);

parse(p,Filename,varargin{:});


if p.Results.force_open==0
    files_out={};
    dates=[];
    id=1;
    
    if ~iscell(Filename)
        [path_tmp,~,~]=fileparts(Filename);
        path_tmp={path_tmp};
    else
        [path_tmp,~,~]=cellfun(@fileparts,Filename,'UniformOutput',0);
        path_tmp=unique(path_tmp);
    end
    
    for i=1:length(path_tmp)
        file_list=dir(fullfile(path_tmp{i},'*.*A'));
        for k=1:length(file_list)
            f_temp=fullfile(file_list(k).folder, file_list(k).name);
            if isfile(f_temp)
                out=textscan(file_list(k).name,'%02f%02f%02f%02f.%02fA');
                dates=[dates datenum([out{1}+2000 out{2} out{3} out{4} zeros(size(out{1})) zeros(size(out{1}))])];
                files_out{id}=f_temp;
                id=id+1;
            end
        end
    end
    
    
    %str_choice={'hours' 'days' 'weeks'};
    str_choice={'hours' 'days'};
    open_by=question_dialog_fig([],'File combination','Do you want to group files by: ','opt',str_choice);
    
    if isempty(open_by)
        new_layers=[];
        return;
    end
    

    switch open_by
        case 'hours'
            div=24;
            t_fmt='dd mmm yyyy HH:MM';
        case 'days'
            div=1;
            t_fmt='dd mmm yyyy';           
        case 'weeks'
            div=1/7;
            t_fmt='dd mmm yyyy';
    end
    
    idx_selected_cell=cellfun(@(x)  find(strcmp(x,files_out)),Filename,'UniformOutput',false);
    idx_selected=[idx_selected_cell{:}];
    
    dates_selected=floor(dates(idx_selected)*div)/div;
    
    dates_to_load=unique(floor(dates*div)/div);
    
    [~,idx_to_load_selected]=intersect(dates_to_load,dates_selected);
    
    dates_to_load_str=cellfun(@(x) datestr(x,t_fmt),(num2cell(dates_to_load)),'un',0);
    
     [idx_out,val] = listdlg_perso([],sprintf('Choose %s(s) to load',open_by),dates_to_load_str,'init_val',idx_to_load_selected);
    if val==0
        new_layers=[];
        return;
    end
    
    dates_selected=unique(floor(dates_to_load(idx_out)*div)/div);
    idx_to_open=[];
    
    for il=1:length(dates_selected)
        idx_to_open=union(idx_to_open,find(floor(dates*div)/div==dates_selected(il)));
    end
    
    Filename_out=files_out(idx_to_open);
    str_disp=sprintf('Opening %.0f %s(s), that is %d files',length(idx_out),open_by,length(idx_to_open));
    
    if ~isempty(p.Results.load_bar_comp)
        p.Results.load_bar_comp.progress_bar.setText(str_disp);
    else
        disp(str_disp)
    end
else
    Filename_out=Filename;
end

[pathname,~]=fileparts(Filename_out{end});

try
    xmlfile = dir(fullfile(pathname,'*.xml'));
    xmlfilename = char(xmlfile(1).name);
    calParms = LoadAZFPxml(pathname,xmlfilename,[]);
catch
    
    [xmlfilename, pathname] = uigetfile({fullfile(pathname,'*.xml')}, 'Select instrument coefficients file');
    if xmlfilename==0
        calParms=[];
    else
        calParms = LoadAZFPxml(pathname,xmlfilename,[]);
    end
end


new_layers=read_asl(Filename_out,...
    'PathToMemmap',p.Results.PathToMemmap,'calParms',calParms,'load_bar_comp',p.Results.load_bar_comp);




end