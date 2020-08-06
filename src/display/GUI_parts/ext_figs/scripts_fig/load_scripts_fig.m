%% load_scripts_fig.m
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
% * |main_figure|: Handle to main ESP3 window
% * |scriptsSummary|: TODO: write description and info on variable
% * |flag|: TODO: write description and info on variable
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
function load_scripts_fig(main_figure,scriptsSummary,flag)
 tag=sprintf('Scripting%s',flag);
 
hfigs=getappdata(main_figure,'ExternalFigures');
if ~isempty(hfigs)
    hfigs(~isvalid(hfigs))=[];  
    idx_tag=find(strcmpi({hfigs(:).Tag},tag));
else
    idx_tag=[];
end

if ~isempty(idx_tag)
    figure(hfigs(idx_tag(1)))
    return;
end

% Column names and column format
columnname = {'Title','Species','Survey','Areas','Author','Script','Created'};
columnformat = {'char','char','char','char','char','char','char'};

script_fig = new_echo_figure(main_figure,'Units','Pixels','Position',[100 100 800 600],'Resize','off',...
    'Name',sprintf('Script Manager (%s)',flag),...
    'Tag',tag,...
    'MenuBar','none');%No Matlab Menu)

uicontrol(script_fig,'style','text','BackgroundColor','White','units','normalized','position',[0.05 0.96 0.15 0.03],'String','Search: ');
script_table.search_box=uicontrol(script_fig,'style','edit','units','normalized','position',[0.2 0.96 0.3 0.03],'HorizontalAlignment','left','Callback',{@search_callback,script_fig});

uicontrol(script_fig,'style','text','BackgroundColor','White','units','normalized','position',[0.55 0.96 0.1 0.03],'String','Filter (or): ');
script_table.title_box=uicontrol(script_fig,'style','checkbox','BackgroundColor','White','units','normalized','position',[0.65 0.96 0.1 0.03],'String','Titles','Value',1,'Callback',{@search_callback,script_fig});
script_table.species_box=uicontrol(script_fig,'style','checkbox','BackgroundColor','White','units','normalized','position',[0.75 0.96 0.1 0.03],'String','Species','Value',1,'Callback',{@search_callback,script_fig});
script_table.voyage_box=uicontrol(script_fig,'style','checkbox','BackgroundColor','White','units','normalized','position',[0.85 0.96 0.1 0.03],'String','Voyage','Value',1,'Callback',{@search_callback,script_fig});


% Create the uitable
script_table.table_main = uitable('Parent',script_fig,...
    'Data', scriptsSummary,...
    'ColumnName', columnname,...
    'ColumnFormat', columnformat,...
    'ColumnEditable', [false false false false false false],...
    'Units','Normalized','Position',[0 0 1 0.95],...
    'RowName',[]);

pos_t = getpixelposition(script_table.table_main);

set(script_table.table_main,'ColumnWidth',{2*pos_t(3)/10, pos_t(3)/10, pos_t(3)/10, pos_t(3)/10, pos_t(3)/10, 2*pos_t(3)/10, 2*pos_t(3)/10});
set(script_table.table_main,'CellSelectionCallback',{@store_selected_script_callback,script_fig})

rc_menu = uicontextmenu(ancestor(script_table.table_main,'figure'));
script_table.table_main.UIContextMenu =rc_menu;
uimenu(rc_menu,'Label','Edit Script','Callback',{@edit_script_callback,script_fig,main_figure,flag});

switch flag
    case 'mbs'
        uimenu(rc_menu,'Label','Run on Crest Files','Callback',{@run_script_callback_v2,script_fig,main_figure,flag,0},'tag','crest');
        uimenu(rc_menu,'Label','Run on Raw Files','Callback',{@run_script_callback_v2,script_fig,main_figure,flag,0},'tag','raw');
        uimenu(rc_menu,'Label','Generate Equivalent  Script','Callback',{@generate_xml_scripts_callback,script_fig,main_figure});
        uimenu(rc_menu,'Label','Populate Logbook from MBS Script','Callback',{@populate_logbook_from_script_callback,script_fig,main_figure});
        
    case 'xml'
        str_run='<HTML><center><FONT color="Green"><b>Run</b></Font> ';
        uimenu(rc_menu,'Label',str_run,'Callback',{@run_script_callback_v2,script_fig,main_figure,flag,0});
        uimenu(rc_menu,'Label','Run and discard layers','Callback',{@run_script_callback_v2,script_fig,main_figure,flag,1});
        uimenu(rc_menu,'Label','Check Script','Callback',{@check_xml_scripts_callback,script_fig,main_figure});
        uimenu(rc_menu,'Label','Load into Script Builder','Callback',{@open_xml_scripts_callback,script_fig,main_figure});
        str_delete='<HTML><center><FONT color="Red"><b>Delete</b></Font> ';
        uimenu(rc_menu,'Label',str_delete,'Callback',{@delete_script_callback,script_fig,main_figure});
        uimenu(rc_menu,'Label','Reload Script Manager','Callback',{@reload_callback,script_fig,main_figure});
       

end
 uimenu(rc_menu,'Label','Change Scripts location folder','Callback',{@load_path_fig_cback,main_figure});

selected_scripts={''};

setappdata(script_fig,'SelectedScripts',selected_scripts);
setappdata(script_fig,'script_table',script_table);
setappdata(script_fig,'DataOri',scriptsSummary);

end

function load_path_fig_cback(src,~,main_figure)
path_fig=load_path_fig([],[],main_figure);
waitfor(path_fig);
script_fig=ancestor(src,'figure');
delete(script_fig);
load_xml_scripts_callback([],[],main_figure);
end

function generate_xml_scripts_callback(~,~,hObject,main_figure)
selected_scripts=getappdata(hObject,'SelectedScripts');
app_path=get_esp3_prop('app_path');

curr_mbs=selected_scripts{1};

if~strcmp(curr_mbs,'')
    [fileNames,outDir]=get_mbs_from_esp2(app_path.cvs_root.Path_to_folder,'MbsId',curr_mbs,'Rev',[]);
end

mbs=mbs_cl();
mbs.readMbsScript(app_path.data_root.Path_to_folder,fileNames{1});
rmdir(outDir,'s');
surv_obj=survey_cl();
surv_obj.SurvInput=mbs.mbs_to_survey_obj('type','raw');


[filename, pathname] = uiputfile('*.xml',...
    'Save survey XML file',...
    fullfile(app_path.scripts.Path_to_folder,[surv_obj.SurvInput.Infos.Voyage '.xml']));

if isequal(filename,0) || isequal(pathname,0)
    return;
end
surv_obj.SurvInput.survey_input_to_survey_xml('xml_filename',fullfile(pathname,filename));

end

function populate_logbook_from_script_callback(~,~,hObject,main_figure)
selected_scripts=getappdata(hObject,'SelectedScripts');
app_path=get_esp3_prop('app_path');

curr_mbs=selected_scripts{1};

if~strcmp(curr_mbs,'')
    [fileNames,outDir]=get_mbs_from_esp2(app_path.cvs_root.Path_to_folder,'MbsId',curr_mbs,'Rev',[]);
end

mbs=mbs_cl();
mbs.readMbsScript(app_path.data_root.Path_to_folder,fileNames{1});
rmdir(outDir,'s');
surv_obj=survey_cl();
surv_obj.SurvInput=mbs.mbs_to_survey_obj('type','raw');
infos=surv_obj.SurvInput.Infos;
for ifile=1:length(mbs.Input.snapshot)
    if ~strcmpi(deblank(mbs.Input.rawFileName{ifile}),'')
        fprintf('Adding Survey Data for File %s\n',mbs.Input.rawFileName{ifile});
        surv=survey_data_cl('Voyage',infos.Voyage,'SurveyName',infos.SurveyName,'Snapshot',mbs.Input.snapshot(ifile),'Stratum',mbs.Input.stratum{ifile},'Transect',mbs.Input.transect(ifile));
        layer_cl.empty.update_echo_logbook_dbfile('Filename',fullfile(mbs.Input.rawDir{ifile},mbs.Input.rawFileName{ifile}),...
            'SurveyData',surv,'Voyage',infos.Voyage,'SurveyName',infos.SurveyName,'main_figure',main_figure);
    end
end

end

function reload_callback(~,~,hObject,main_figure)
delete(hObject);
load_xml_scripts_callback([],[],main_figure)
end

function open_xml_scripts_callback(src,~,hObject,main_figure,flag)
selected_scripts=getappdata(hObject,'SelectedScripts');
app_path=get_esp3_prop('app_path');
%layers=get_esp3_prop('layers');
selected_scripts_full=cellfun(@(x) fullfile(app_path.scripts.Path_to_folder,x),selected_scripts,'UniformOutput',0);

surv_obj = survey_cl();
surv_obj.SurvInput = parse_survey_xml(selected_scripts_full{end});

 xml_scrip_fig=create_xml_script_gui('main_figure',main_figure,'survey_input_obj',surv_obj.SurvInput,'existing',1);
waitfor(xml_scrip_fig);
end

function delete_script_callback(src,~,hObject,main_figure)
selected_scripts=getappdata(hObject,'SelectedScripts');
app_path=get_esp3_prop('app_path');
selected_scripts=cellfun(@(x) fullfile(app_path.scripts.Path_to_folder,x),selected_scripts,'UniformOutput',0);
for i=1:numel(selected_scripts)
    try
        if isfile(selected_scripts{i})
            fprintf('Removing script %s\n',selected_scripts{i});
            delete(selected_scripts{i});
        end
        
    catch
        fprintf('Could not delete script %s\n',selected_scripts{i});
    end
end
reload_callback([],[],hObject,main_figure);
end

function run_script_callback_v2(src,~,hObject,main_figure,flag,discard_lay)

selected_scripts=getappdata(hObject,'SelectedScripts');
app_path=get_esp3_prop('app_path');

selected_scripts=cellfun(@(x) fullfile(app_path.scripts.Path_to_folder,x),selected_scripts,'UniformOutput',0);

if ispc()
    choice=question_dialog_fig(main_figure,'Update display','Do you want show the echograms as you load them (takes more time...)','timeout',5);
    switch choice
        case 'Yes'
            update_display=1;
        otherwise
            update_display=0;
    end
else
    update_display=0;
end

esp3_obj=getappdata(groot,'esp3_obj');

esp3_obj.run_scripts(selected_scripts,...
    'discard_loaded_layers',discard_lay>0,...
    'origin',flag,...
    'tag',src.Tag,...
    'update_display_at_loading',update_display);

end

function check_xml_scripts_callback(~,~,hObject,main_figure)
app_path=get_esp3_prop('app_path');
selected_scripts=getappdata(hObject,'SelectedScripts');
surv_obj=survey_cl();
for uis=1:numel(selected_scripts)
    surv_obj.SurvInput=parse_survey_xml(fullfile(app_path.scripts.Path_to_folder,selected_scripts{uis}));
    
    if isempty(surv_obj.SurvInput)
        print_errors_and_warnings([],'warning','Could not parse the File describing the survey...');
    end
    
    [valid,~]=surv_obj.SurvInput.check_n_complete_input();
    
    if valid==0
        print_errors_and_warnings([],'warning',sprintf('It looks like there is a problem with XML survey file %s\n',selected_scripts{uis}));
    else
        disp_perso(main_figure,'Script appears to be valid...')
    end
end
end

function edit_script_callback(~,~,hObject,main_figure,flag)
selected_scripts=getappdata(hObject,'SelectedScripts');
app_path=get_esp3_prop('app_path');
switch flag
    case 'mbs'
        if~strcmp(selected_scripts,'')
            [fileNames,outDir]=get_mbs_from_esp2(app_path.cvs_root.Path_to_folder,'MbsId',selected_scripts{end},'Rev',[]);
            pause(1);
            for ifi=1:numel(fileNames)
            open_txt_file(fileNames{end})
            end
            
            pause(0.5);
            rmdir(outDir,'s');
        end
        
    case 'xml'
        if isfile(fullfile(app_path.scripts.Path_to_folder,selected_scripts{end}))
           open_txt_file(fullfile(app_path.scripts.Path_to_folder,selected_scripts{end}));
        else
            fprintf('Could not find script %s\n',selected_scripts{end});
        end
end
end

function store_selected_script_callback(src,event,hObject)

if size(event.Indices,1)>0
    selected_scripts=src.Data(unique(event.Indices(:,1)),6);
else
    selected_scripts={''};
end
setappdata(hObject,'SelectedScripts',selected_scripts);
end

function search_callback(~,~,script_fig)
table=getappdata(script_fig,'script_table');
data_ori=getappdata(script_fig,'DataOri');
text_search=regexprep(get(table.search_box,'string'),'[^\w'']','');
title_search=get(table.title_box,'value');
voyage_search=get(table.voyage_box,'value');
species_search=get(table.species_box,'value');

if isempty(text_search)||(voyage_search==0&&title_search==0&&species_search==0)
    data=data_ori;
else
    
    if voyage_search>0
        voyages=regexprep(data_ori(:,3),'[^\w'']','');
        out_voyage=regexpi(voyages,text_search);
        idx_voyage=cellfun(@(x) ~isempty(x),out_voyage);
    else
        idx_voyage=zeros(size(data_ori,1),1);
    end
    
    if species_search>0
        species=regexprep(data_ori(:,2),'[^\w'']','');
        out_species=regexpi(species,text_search);
        idx_species=cellfun(@(x) ~isempty(x),out_species);
    else
        idx_species=zeros(size(data_ori,1),1);
    end
    
    if title_search>0
        titles=regexprep(data_ori(:,1),'[^\w'']','');
        out_title=regexpi(titles,text_search);
        idx_title=cellfun(@(x) ~isempty(x),out_title);
    else
        idx_title=zeros(size(data_ori,1),1);
    end
    
    
    data=data_ori(idx_voyage|idx_title|idx_species,:);
end

set(table.table_main,'Data',data);
setappdata(script_fig,'script_table',table);
end

