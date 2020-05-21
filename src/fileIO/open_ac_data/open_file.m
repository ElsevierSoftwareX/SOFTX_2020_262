
%% open_file.m
%
% ESP3 main function to open new file(s)
%
%% Help
%
% *USE*
%
% TODO
%
% *INPUT VARIABLES*
%
% * |file_id| File ID (Required. Valid options: char for a single filename,
% cell for one or several filenames, |0| to open dialog box to prompt user
% for file(s), |1| to open next file in folder or |2| to open previous file
% in folder.
% * |main_figure|: Handle to main ESP3 window (Required).
%
% *OUTPUT VARIABLES*
%
% NA
%
% *RESEARCH NOTES*
%
% * Could upgrade input variables management to input parser
% * Update if new files format to be supported
% * Not sure why the ~,~ at the beginning?
%
% *NEW FEATURES*
%
% * 2017-03-22: header and comments updated according to new format (Alex Schimel)
% * 2017-03-17: reformatting comment and header for compatibility with publish (Alex Schimel)
% * 2017-03-02: Comments and header (Alex Schimel)
% * YYYY-MM-DD: first version (Yoann Ladroit)
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function output=open_file(~,~,file_id,main_figure)

%profile on;
%%% Grab current layer (files data) and paths
layer = get_current_layer();
layers = get_esp3_prop('layers');
app_path = get_esp3_prop('app_path');
esp3_obj=getappdata(groot,'esp3_obj');

output=[];
%%% Check if there are unsaved new bottom and regions
check_saved_bot_reg(main_figure);

%%% Exit if input file was bad
% (put this at beginning and through input parser)
if isempty(file_id)
    return;
end
up_disp=0;

%%% Get a default path for the file selection dialog box
if ~isempty(layer)
    [path_lay,~] = layer.get_path_files();
    if ~isempty(path_lay)
        % if file(s) already loaded, same path as first one in list
        file_path = path_lay{1};
    else
        % config default path if none
        file_path = app_path.data.Path_to_folder;
    end
else
    % config default path if none
    file_path = app_path.data.Path_to_folder;
end


%%% Grab filename(s) to open
if ischar(file_id) || iscell( file_id)% if input variable is the filename(s) itself
    
    Filename = file_id;
    
else
    Filename = [];
    switch file_id
        case 0 % if requesting opening a selection dialog box
            
            Filename=get_compatible_ac_files(file_path);
            
        case {1 2} % if requesting to open next or previousfile in folder
            
            % Grab filename(s) in current layer
            if ~isempty(layer)
                [~,Filenames] = layer.get_path_files();
            else
                return;
            end
            
            % find all files in path
            
            file_list = list_ac_files(file_path,0);
            
            % find the next file in folder after current file
            idx_f=find(ismember(file_list,Filenames));
            
            if ~isempty(idx_f)
                if file_id==1
                    id_open=idx_f(end)+1;
                else
                    id_open=idx_f(1)-1;
                end
            else
                return;
            end
            
            if id_open>0&&id_open<=numel(file_list)
                Filename=fullfile(file_path,file_list{id_open});
            end
            
            
    end
    
end

%%% Exit if still no file at this point 
if isempty(Filename)
    return;
end
if isequal(Filename, 0)
    return;
end

%%% Turn filename to cell if still not done at this point 
if ~iscell(Filename)
    Filename_tot = {Filename};
else
    Filename_tot = Filename;
end

if ~isempty(layers)
    [old_files,~]=layers.list_files_layers();
    idx_already_open=find(cellfun(@(x) any(strcmpi(x,old_files)),Filename_tot));
    
    for iii=1:numel(idx_already_open)
        warndlg_perso(main_figure,'',sprintf('File %s already open in existing layer',Filename_tot{idx_already_open(iii)}))
    end
    Filename_tot(idx_already_open)=[];
    
    [~,files_lay_old]=layers.get_path_files();
    
    idx_same_name=find(cellfun(@(x) any(contains(x,files_lay_old)),Filename_tot));
    idx_same_name=setdiff(idx_same_name,idx_already_open);
    
    for iii=1:numel(idx_same_name)
        warndlg_perso(main_figure,'',sprintf('File with same name %s already open in existing layer\n',Filename_tot{idx_same_name(iii)}));
    end
    
    Filename_tot(idx_same_name)=[];
else
    old_files={};
end


%%% Get types of files to open

ftype_cell = cellfun(@get_ftype,Filename_tot,'un',0);

if isempty(ftype_cell)
    hide_status_bar(main_figure);
    return;
end

%%% Find each ftypes in list to batch process the opening
[ftype_unique,~,ic] = unique(ftype_cell);

load_bar_comp=getappdata(main_figure,'Loading_bar');
show_status_bar(main_figure);

output=zeros(1,numel(Filename_tot));
new_layers_tot=[];
try
    %%% File opening section, by type of file
    for itype = 1:length(ftype_unique)
        
        % Grab filenames for this ftype
        Filename = Filename_tot(ic==itype);
        ftype = ftype_unique{itype};
        CVSCheck=0;
        dfile=0;
        % Figure if the files requested to be open are part of a transect that
        % include other files not requested to be opened. This functionality is
        % not available for all types of files
        switch ftype
            case {'EK60','EK80','FCV30'}
                missing_files = find_survey_data_db(Filename);
                idx_miss=cellfun(@(x)~any(strcmpi(x,old_files)),missing_files);
                missing_files=missing_files(idx_miss);
                if ~isempty(missing_files)
                    % If there are, prompt user if they want them added to the
                    % list of files to open
                    war_str=sprintf('It looks like you are trying to open incomplete transects (%.0f missing files)... Do you want load the rest as well?',numel(missing_files));
                    choice=question_dialog_fig(main_figure,'',war_str,'timeout',5);
                    
                    switch choice
                        case 'Yes'
                            Filename = union(Filename,missing_files);
                        case 'No'
                            
                        otherwise
                            
                    end
                end
            case 'ASL'
                
                [path_asl_tmp,file_asl_tmp,ext_asl_tmp]=cellfun(@fileparts,Filename,'un',0);
                [path_asl,idx_unique]=unique(path_asl_tmp);
                Filename=cellfun(@(x,y,z) fullfile(x,[y z]),path_asl,file_asl_tmp(idx_unique),ext_asl_tmp(idx_unique),'un',0);
            case {'TOPAS'}
                
            case 'CREST'
                % Prompt user on opening raw or original and handle the answer
                war_str='Do you want to open associated Raw File or original d-file?';
                choice=question_dialog_fig(main_figure,'d-file/raw_file',war_str,'opt',{'raw file','d-file'},'timeout',10);
                switch choice
                    case 'raw file'
                        dfile = 0;
                    case 'd-file'
                        dfile = 1;
                end
                if isempty(choice)
                    continue;
                end
                
                % Prompt user to load bottom and regions and handle the answer
                war_str='Do you want to load associated CVS Bottom and Region?';
                choice=question_dialog_fig(main_figure,'Bottom/Region',war_str,'timeout',10);
                
                switch choice
                    case 'Yes'
                        CVSCheck = 1;
                    case 'No'
                        CVSCheck = 0;
                end
                if isempty(choice)
                    CVSCheck = 0;
                end
                
            case 'db'
                for ifi=1:length(Filename)
                    load_logbook_tab_from_db(main_figure,0,1,Filename{ifi});
                end
                continue;
                
            case 'unknown'
                str_disp=sprintf('Could not find file(s): %s',strjoin(Filename,' ,'));
                load_bar_comp.progress_bar.setText(str_disp);
                continue;
            otherwise
                
                continue;
                
        end
        %profile on
        %freq_to_open=[];
        
        if isempty(layer)
            chan={};
        else
            chan=layer.ChannelID;
        end
        
        %profile on;
        [new_layers,multi_lay_mode]=open_file_standalone(Filename,ftype,...
            'already_opened_files',old_files,...
            'Channels',chan,...
            'PathToMemmap',app_path.data_temp.Path_to_folder,...
            'load_bar_comp',load_bar_comp,...
            'LoadEKbot',1,...
            'CVSCheck',CVSCheck,...
            'CVSroot',app_path.cvs_root.Path_to_folder,...
            'dfile',dfile);
        %profile off;
        %profile viewer
        if isempty(new_layers)
            continue;
        end
        % Open the files. Different behavior per type of file
        switch ftype
            
            case {'CREST'}
                
                
            case {'EK60','EK80','ASL','TOPAS','FCV30'}
                
                disp_perso(main_figure,'Loading Bottom and regions');
                
                %set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',numel(new_layers),'Value',0);
                
                for i=1:numel(new_layers)
                    %set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',numel(new_layers),'Value',i);
                    try
                        % try to load bottom and regions from xml files
                        new_layers(i).load_bot_regs();
                    catch err
                        disp(err.message);
                        lst=list_layers(new_layers(i),'nb_char',80);
                        disp_perso(main_figure,sprintf('Could not load bottom and region for layer %s',lst{1}));
                    end
                end
                
                
                load_bar_comp.progress_bar.setText('');
                
                
                multi_lay_mode=0;
                
            case 'Unknown'
                for ifi=1:length(Filename)
                    disp_perso(main_figure,sprintf('Could not open %s',Filename{ifi}));
                end
                continue;
            otherwise
                for ifi=1:length(Filename)
                    disp_perso(main_figure,sprintf('Unrecognized File type for Filename %s',Filename{ifi}));
                end
                continue;
        end
        new_layers_tot=[new_layers_tot new_layers];
        
    end
    
    if isempty(new_layers_tot)
        hide_status_bar(main_figure);
        return;
    end
    
    [filenames_openned,~]=new_layers_tot.list_files_layers();
    files_lay=new_layers_tot(1).Filename;
    output=ismember(Filename_tot,filenames_openned);
    
    esp3_obj.add_layers_to_esp3(new_layers_tot,multi_lay_mode);
    
    if ~(isempty(esp3_obj.layers)||~exist('files_lay','var'))
        [idx,~]=esp3_obj.layers.find_layer_idx_files(files_lay);
        set_current_layer(esp3_obj.layers(idx(1)));
        up_disp=1;
    end
    
    
catch err
    print_errors_and_warnings(1,'error',err);
end

%%% Update display
if up_disp>0
    loadEcho(main_figure);
end
% if stop_process
%     main_figure.CurrentCharacter='a';
% end
hide_status_bar(main_figure);


%  profile off;
%  profile viewer;




end