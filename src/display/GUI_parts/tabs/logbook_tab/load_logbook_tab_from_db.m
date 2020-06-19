%% load_logbook_tab_from_db.m
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
% * |reload|: TODO: write description and info on variable
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
% * 2017-03-28: header (Alex Schimel)
% * YYYY-MM-DD: first version (Yoann Ladroit)
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function load_logbook_tab_from_db(main_figure,varargin)

p = inputParser;
addRequired(p,'main_figure',@ishandle);
addOptional(p,'reload',0,@isnumeric);
addOptional(p,'new_logbook',0,@isnumeric);
addOptional(p,'filename','',@ischar);
addParameter(p,'layer',layer_cl.empty,@(x) isa(x,'layer_cl'));
parse(p,main_figure,varargin{:});

new_logbook=p.Results.new_logbook;
reload=p.Results.reload;
if isempty(p.Results.layer)
    layer=get_current_layer();
else
    layer=p.Results.layer;
end

app_path=get_esp3_prop('app_path');
try
    
    if isempty(layer)||new_logbook>0
        if isempty(p.Results.filename)||~exist(p.Results.filename,'file')
            [~,path_f]= uigetfile({fullfile(app_path.data.Path_to_folder,'echo_logbook.db')}, 'Pick a logbook file','MultiSelect','off');
            if path_f==0
                return;
            end
            [path_f,~,~]=fileparts(path_f);
        else
            [path_f,~,~]=fileparts(p.Results.filename);
        end
        path_lay={path_f};
        file_add={};
    else
        
        switch layer.Filetype
            case {'CREST'}
                return;
            otherwise
                [path_lay,~]=get_path_files(layer);
                path_lay=unique(path_lay);
        end
        file_add=layer.Filename;
        
    end
    
    for up=1:numel(path_lay)
        path_f=path_lay{up};
        
        db_file=fullfile(path_f,'echo_logbook.db');
        
        if ~isfile(db_file)
            initialize_echo_logbook_dbfile(path_f,main_figure,0)
        end
        layer_cl().update_echo_logbook_dbfile('main_figure',main_figure,'DbFile',db_file);
        %surv_data_struct=import_survey_data_db(db_file);
        try
            dbconn=sqlite(db_file,'connect');
            read_only=0;
        catch
            dbconn=sqlite(db_file,'readonly');
            read_only=1;
        end
        % user = '';
        % password = '';
        % driver = 'org.sqlite.JDBC';
        % protocol = 'jdbc';
        % subprotocol = 'sqlite';
        % resource = db_file;
        % url = strjoin({protocol, subprotocol, resource}, ':');
        % dbconn = database(db_file, user, password, driver, url);
        
        
        
        data_survey=dbconn.fetch('select Voyage,SurveyName from survey ');
        
        if isempty(data_survey)
            data_survey={'' ''};
        end
        
        dest_fig=getappdata(main_figure,'echo_tab_panel');
        
        tag=sprintf('logbook_%s',path_f);
        tab_obj=findobj(dest_fig,'Tag',tag);
        
        if ~isempty(tab_obj)
            if reload==0
                if strcmp(tab_obj(1).Type,'uitab')
                    tab_obj(1).Parent.SelectedTab=tab_obj(1);
                end
                continue;
            else
                surv_data_tab=tab_obj(1);
                surv_data_table=getappdata(surv_data_tab,'surv_data_table');
                set(surv_data_table.voy,'String',sprintf('Voyage %s, Survey: %s',data_survey{1},data_survey{2}))
                set(surv_data_tab,'Title',sprintf('Logbook %s',data_survey{1}));
            end
        else
            if reload==0
                userdata.db_file=db_file;
                surv_data_tab=uitab(dest_fig,'Title',sprintf('Logbook %s',data_survey{1}),'Tag',tag,'BackgroundColor','White','Userdata',userdata);
                
                surv_data_table.file=uicontrol(surv_data_tab,'style','checkbox','BackgroundColor','White','units','normalized','position',[0.55 0.95 0.04 0.04],'String','File','Value',1,'Callback',{@search_callback,surv_data_tab});
                surv_data_table.snap=uicontrol(surv_data_tab,'style','checkbox','BackgroundColor','White','units','normalized','position',[0.6 0.95 0.04 0.04],'String','Snap','Value',1,'Callback',{@search_callback,surv_data_tab});
                surv_data_table.type=uicontrol(surv_data_tab,'style','checkbox','BackgroundColor','White','units','normalized','position',[0.65 0.95 0.04 0.04],'String','Type','Value',1,'Callback',{@search_callback,surv_data_tab});
                surv_data_table.strat=uicontrol(surv_data_tab,'style','checkbox','BackgroundColor','White','units','normalized','position',[0.7 0.95 0.04 0.04],'String','Strat','Value',1,'Callback',{@search_callback,surv_data_tab});
                surv_data_table.trans=uicontrol(surv_data_tab,'style','checkbox','BackgroundColor','White','units','normalized','position',[0.75 0.95 0.04 0.04],'String','Trans','Value',1,'Callback',{@search_callback,surv_data_tab});
                surv_data_table.reg=uicontrol(surv_data_tab,'style','checkbox','BackgroundColor','White','units','normalized','position',[0.8 0.95 0.04 0.04],'String','Tag','Value',1,'Callback',{@search_callback,surv_data_tab});
                
                
                surv_data_table.voy=uicontrol(surv_data_tab,'style','text','BackgroundColor','White','units','normalized','position',[0.05 0.95 0.3 0.04],'String',sprintf('Voyage %s, Survey: %s',data_survey{1},data_survey{2}));
                uicontrol(surv_data_tab,'style','text','BackgroundColor','White','units','normalized','position',[0.35 0.95 0.1 0.05],'String','Search :');
                
                surv_data_table.search_box=uicontrol(surv_data_tab,'style','edit','units','normalized','position',[0.45 0.95 0.1 0.04],'HorizontalAlignment','left','Callback',{@search_callback,surv_data_tab});
                
                tab_menu = uicontextmenu(ancestor(surv_data_tab,'figure'));
                surv_data_tab.UIContextMenu=tab_menu;
                uimenu(tab_menu,'Label','Close Logbook','Callback',{@close_logbook_tab,surv_data_tab});
                
                if strcmp(surv_data_tab.Type,'uitab')
                    surv_data_tab.Parent.SelectedTab=surv_data_tab;
                end
                
            else
                continue;
            end
        end
        
        if reload==0
            
            data_logbook=dbconn.fetch('select Filename from logbook order by datetime(StartTime)');
            [list_raw,~]=list_ac_files(path_f,1);
            
            if read_only>0
                not_in=setdiff(data_logbook,list_raw);
                if ~isempty(not_in)
                    for i=1:numel(not_in)
                        fprintf('Removing %s from logbook\n',not_in{i});
                        dbconn.exec(sprintf('DELETE FROM logbook WHERE Filename=''%s''',not_in{i}));
                    end
                    data_logbook=dbconn.fetch('select Filename from logbook order by datetime(StartTime)');
                end
            end
            nb_lines=size(data_logbook,1);
            
            if nb_lines==0
                delete(surv_data_tab);
                dbconn.close();
                continue;
            end
            
            createlogbookTable(dbconn);
            
            survDataSummary=update_data_table(dbconn,[],data_logbook,path_f);
            
            
            [types,~]=init_trans_type();
            % Column names and column format
            columnname = {'','File','Snap.','Type','Strat.','Trans.','Bot','Reg. Tags','Comment','Start Time','End Time','id'};
            columnformat = {'logical' 'char','numeric',types,'char','numeric','logical','char','char','char','char','numeric'};
            
            
            % Create the uitable
            surv_data_table.table_main = uitable('Parent',surv_data_tab,...
                'Data', survDataSummary,...
                'ColumnName', columnname,...
                'ColumnFormat', columnformat,...
                'CellSelectionCallback',{@cell_select_cback,surv_data_tab,main_figure},...
                'ColumnEditable', [true false true true true true false false true false false false],...
                'Units','Normalized','Position',[0 0 1 0.94],...
                'RowName',[]);
            
            %set(surv_data_tab,'SizeChangedFcn',@resize_table);
            
            set_auto_resize_table(surv_data_table.table_main);
            %set_sortable(jTable,true);
            pos_t = getpixelposition(surv_data_table.table_main);
            set(surv_data_table.table_main,'ColumnWidth',...
                num2cell(pos_t(3)*[1/36,4*1/18, 1/18, 2*1/18,1/18, 1/18,1/36,3*1/36, 2*1/18, 2*1/18,2*1/18, 1/36]));
            set(surv_data_table.table_main,'CellEditCallback',{@edit_surv_data_db,surv_data_tab,main_figure});
            %set(surv_data_table.table_main,'CellSelectionCallback',{@update_surv_data_struct,surv_data_tab});
            
            
            rc_menu = uicontextmenu(ancestor(surv_data_table.table_main,'figure'));
            surv_data_table.table_main.UIContextMenu =rc_menu;
            open_menu=uimenu(rc_menu,'Label','Open');  
            select_menu=uimenu(rc_menu,'Label','Select'); 
            mod_survey_menu=uimenu(rc_menu,'Label','Edit SurveyData');
            survey_menu=uimenu(rc_menu,'Label','Import/Export SurveyData');
            process_menu=uimenu(rc_menu,'Label','Process'); 
            map_menu=uimenu(rc_menu,'Label','Map');
           

            uimenu(open_menu,'Label','Open highlighted file(s)','Callback',{@open_files_callback,surv_data_tab,main_figure,'high'});
            uimenu(open_menu,'Label','Open selected file(s)','Callback',{@open_files_callback,surv_data_tab,main_figure,'sel'});
            uimenu(open_menu,'Label','Open Script Builder with selected file(s)','Callback',{@generate_xml_callback,surv_data_tab,main_figure});
            
            copy_menu=uimenu(rc_menu,'Label','Copy');
            uimenu(copy_menu,'Label','Copy highlighted file(s) to other folder','Callback',{@copy_to_other_cback,surv_data_tab,main_figure,'high'});
            uimenu(copy_menu,'Label','Copy selected file(s) to other folder','Callback',{@copy_to_other_cback,surv_data_tab,main_figure,'sel'});
            
            uimenu(select_menu,'Label','Select all','Callback',{@selection_callback,surv_data_tab},'Tag','se');
            uimenu(select_menu,'Label','Deselect all','Callback',{@selection_callback,surv_data_tab},'Tag','de');
            uimenu(select_menu,'Label','Invert Selection','Callback',{@selection_callback,surv_data_tab},'Tag','inv');
            uimenu(select_menu,'Label','Select highlighted files','Callback',{@selection_callback,surv_data_tab},'Tag','high');
            uimenu(select_menu,'Label','De-Select highlighted files','Callback',{@selection_callback,surv_data_tab},'Tag','dehigh');
            uimenu(process_menu,'Label','Plot/Display bad pings per files','Callback',{@plot_bad_pings_callback,surv_data_tab,main_figure});
            
            uimenu(survey_menu,'Label','Load transect data from .csv','Callback',{@load_logbook_from_csv_callback,main_figure,path_f});
            uimenu(survey_menu,'Label','Load transect data from .xml','Callback',{@load_logbook_from_xml_callback,main_figure,path_f});
            uimenu(survey_menu,'Label','Export metadata to .csv','Callback',{@export_metadata_to_csv_callback,main_figure,path_f});
            uimenu(survey_menu,'Label','Export to html and display','Callback',{@export_metadata_to_html_callback,main_figure,path_f});
            
            uimenu(map_menu,'Label','Display selected file(s) positions','Callback',{@display_files_tracks_cback,surv_data_tab,main_figure,''})
            uimenu(map_menu,'Label','Export selected file(s) positions to .shp/.csv','Callback',{@display_files_tracks_cback,surv_data_tab,main_figure,'save'})
            
            uimenu(mod_survey_menu,'Label','Edit highlighted files survey_data','Callback',{@edit_survey_data_log_cback,surv_data_tab,main_figure,'high'});
            if ~isdeployed()
                uimenu(mod_survey_menu,'Label','Set Night Steams','Callback',{@set_type_night_steam,surv_data_tab,main_figure});
            end
            
            setappdata(surv_data_tab,'path_data',path_f);
            setappdata(surv_data_tab,'surv_data_table',surv_data_table);
            setappdata(surv_data_tab,'data_ori',survDataSummary);
            setappdata(surv_data_tab,'dbconn',dbconn);
            set(surv_data_tab,'DeleteFcn',@delete_logbook_tab);
            surv_data_tab.Parent.SelectedTab=surv_data_tab;
            
        else
            reload_logbook_fig(surv_data_tab,file_add);
        end
    end
catch err
    warndlg_perso(main_figure,'Could not connect to Logbook','Could not connect to Logbook');
    print_errors_and_warnings(1,'error',err);
end
end

%%
function close_logbook_tab(~,~,tab)
delete(tab);
end

%%
function delete_logbook_tab(src,~)
dbconn=getappdata(src,'dbconn');
dbconn.close();
disp('Logbook connection closed');
delete(src);
end

function copy_to_other_cback(src,evt,surv_data_tab,main_figure,sel_or_high)
surv_data_table=getappdata(surv_data_tab,'surv_data_table');
data_ori=get(surv_data_table.table_main,'Data');

switch sel_or_high
    case 'sel'
        selected_files=unique(data_ori([data_ori{:,1}],2));
    case 'high'
        selected_files=unique(surv_data_table.table_main.UserData.highlighted_files);
end

path_f=getappdata(surv_data_tab,'path_data');
files=fullfile(path_f,selected_files);

path_tmp = uigetdir(path_f,...
    'Copy to folder');
if isequal(path_tmp,0)
    return;
end
show_status_bar(main_figure);
load_bar_comp = getappdata(main_figure,'Loading_bar');

set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',numel(files), 'Value',0);

for ui=1:numel(files)
    load_bar_comp.progress_bar.setText(sprintf('Copying %s',files{ui}));
    [status,msg,~] = copyfile(files{ui}, path_tmp, 'f');
%     switch ispc
%         case 1
%             [status,~] = system(sprintf('copy %s %s',files{ui},path_tmp),'-echo');
%         case 0
%             [status,~] = system(sprintf('cp %s %s',files{ui},path_tmp),'-echo');
%     end
    
    if ~status
        warndlg_perso(main_figure,'Error copying file',sprintf('Error copying %s: \n%s',files{ui},msg));
        %warndlg_perso(main_figure,'Error copying file',sprintf('Error copying %s',files{ui}));
    end
    set(load_bar_comp.progress_bar,'Value',ui);
end

hide_status_bar(main_figure);
end


%%
function display_files_tracks_cback(src,evt,surv_data_tab,main_figure,f_save)

surv_data_table=getappdata(surv_data_tab,'surv_data_table');
data_ori=get(surv_data_table.table_main,'Data');
selected_files=unique(data_ori([data_ori{:,1}],2));
path_f=getappdata(surv_data_tab,'path_data');
disp=1;

if ~isempty(f_save)
    % prompt for output file
    [csvfilename, csvpathname] = uiputfile({'*.shp', 'Shapefile';'*.csv' 'CSV';},...
        'Define output .csv/.shp file for GPS data',...
        fullfile(path_f,'gps_data.shp'));
    if isequal(csvfilename,0) || isequal(csvpathname,0)
        return
    end
    f_save=fullfile(csvpathname,csvfilename);
    disp=0;
end
files=fullfile(path_f,selected_files);

plot_gps_track_from_filenames(main_figure,files,disp,f_save);

end

%%
function plot_bad_pings_callback(src,~,surv_data_tab,main_figure)

surv_data_table=getappdata(surv_data_tab,'surv_data_table');
data_ori=get(surv_data_table.table_main,'Data');
selected_files=unique(data_ori([data_ori{:,1}],2));
path_f=getappdata(surv_data_tab,'path_data');
files=fullfile(path_f,selected_files);

[nb_bad_pings,nb_pings,files_out,freq_vec,cids]=get_bad_ping_number_from_bottom_xml(files);

[filename, pathname]=uiputfile({'*.txt','Text File'},'Save Bad Ping file',...
    fullfile(path_f,'bad_pings_f'));

if isequal(filename,0) || isequal(pathname,0)
    fid=1;
else
    fid_f=fopen(fullfile(pathname,filename),'w');
    if fid_f~=-1
        fid=[1 fid_f];
    end
end
h_fig=new_echo_figure(main_figure);
ax=axes(h_fig);hold(ax,'on');grid(ax,'on');ylabel('%')
title(ax,filename,'Interpreter','none');
for ifreq=1:length(freq_vec)
    plot_temp=plot(ax,nb_bad_pings{ifreq}./nb_pings{ifreq}*100,'Marker','+');
    
    set(plot_temp,'ButtonDownFcn',{@display_filename_callback,files_out{ifreq}});
    
    for i=1:length(fid)
        fprintf(fid(i),'Bad Pings for channel %s\n',cids{ifreq});
        for i_sub=1:length(nb_bad_pings{ifreq})
            fprintf(fid(i),'%s %.2f %s}\n',files_out{ifreq}{i_sub},nb_bad_pings{ifreq}(i_sub)./nb_pings{ifreq}(i_sub)*100,cids{ifreq});
        end
        fprintf(fid(i),'\n');
    end
    
end
legend(ax,cids);
for i=1:length(fid)
    if fid(i)~=1
        fclose(fid(i));
    end
end


end

%%
function display_filename_callback(src,evt,file_list)

ax=src.Parent;

text_obj=findobj(ax,'Tag','fname');
delete(text_obj);

[~,idx]=nanmin((src.XData-evt.IntersectionPoint(1)).^2+(src.YData-evt.IntersectionPoint(2)).^2);
axes(ax);
text(evt.IntersectionPoint(1),evt.IntersectionPoint(2),file_list{idx},'Tag','fname');


end

%%
function edit_survey_data_log_cback(src,evt,surv_data_tab,main_figure,sel_or_high)
surv_data_table=getappdata(surv_data_tab,'surv_data_table');
data=getappdata(surv_data_tab,'data');
dbconn=getappdata(surv_data_tab,'dbconn');

if dbconn.IsReadOnly
    fprintf('Database file is readonly... Check file permissions\n');
    return;
end

switch sel_or_high
    case 'sel'
        idx=find([data{:,1}]);
    case 'high'
        idx=surv_data_table.table_main.UserData.highlighted_idx;
end

if isempty(idx)
    return;
end


surv=survey_data_cl();
tt='Edit survey Data';

data_ori=getappdata(surv_data_tab,'data_ori');
[surv,modified]=edit_survey_data_fig(main_figure,surv,{'off' 'off' 'on' 'on' 'on' 'on' 'on'},tt);

if isempty(surv)||all(modified==0)
    return;
end
load_bar_comp=show_status_bar(main_figure,0);
%set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',100, 'Value',0);
load_bar_comp.progress_bar.setText('Updating Logbook');

fields={'Voyage' 'SurveyName' 'Snapshot' 'Type' 'Stratum' 'Transect' 'Comment'};
fields_idx=[nan nan 3 4 5 6 9];
disp('Updating Logbook')
for i=1:numel(idx)
    filename=surv_data_table.table_main.Data{idx(i),2};
    st=surv_data_table.table_main.Data{idx(i),10};
    for ifi=1:numel(fields)
        if modified(ifi)&&~isnan(fields_idx(ifi))
            if isnumeric(surv.(fields{ifi}))
                sql_query=sprintf('UPDATE logbook SET %s=%d WHERE Filename = ''%s'' and StartTime = ''%s''',...
                    (fields{ifi}),surv.(fields{ifi}),filename,st);
            else
                sql_query=sprintf('UPDATE logbook SET %s="%s" WHERE Filename = ''%s'' and StartTime = ''%s''',...
                    (fields{ifi}),surv.(fields{ifi}),filename,st);
            end
            dbconn.exec(sql_query);
            idx_struct=surv_data_table.table_main.Data{idx(i),12};
            data_ori{idx_struct,ifi}= surv.(fields{ifi});
            surv_data_table.table_main.Data{idx(i),fields_idx(ifi)}= surv.(fields{ifi});
        end
    end
end

setappdata(surv_data_tab,'data_ori',data_ori);
import_survey_data_callback([],[],main_figure);
set(load_bar_comp.progress_bar,'Value',100);
load_bar_comp.progress_bar.setText('');
hide_status_bar(main_figure);
disp('Done.')
end

%%
function cell_select_cback(src,evt,surv_data_tab,main_figure)
parent=ancestor(src,'figure');
pathf=getappdata(surv_data_tab,'path_data');
src.UserData.highlighted_idx=unique(evt.Indices(:,1));
src.UserData.highlighted_files=src.Data(unique(evt.Indices(:,1)),2);

switch parent.SelectionType
    case 'open'
        if ~isempty(evt.Indices)
            open_file([],[],fullfile(pathf,src.Data{evt.Indices(1,1),2}),main_figure)
        end
end


end

%%
function edit_surv_data_db(src,evt,surv_data_tab,main_figure)

if isempty(evt.Indices)
    return;
end

% load_bar_comp=show_status_bar(main_figure);
% set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',100, 'Value',0);
% load_bar_comp.progress_bar.setText('Updating Logbook');

data_ori = getappdata(surv_data_tab,'data_ori');
dbconn = getappdata(surv_data_tab,'dbconn');

if isnan(src.Data{evt.Indices(1,1),evt.Indices(1,2)})
    src.Data{evt.Indices(1),evt.Indices(2)}=0;
end

idx_struct = src.Data{evt.Indices(1,1),12};
fields = { '' 'Filename' 'Snapshot' 'Type' 'Stratum' 'Transect' '' '' 'Comment' 'StartTime' 'EndTime' ''};

col_id = evt.Indices(1,2);
row_id = evt.Indices(1,1);

switch col_id
    
    case {1}
        data_ori{idx_struct,col_id} = src.Data{row_id,col_id};
        setappdata(surv_data_tab,'data_ori',data_ori);
        return;
    case{3,4,5,6,9}
        filename = src.Data{row_id,2};
        %         snap=src.Data{row_id,3};
        %         type=src.Data{row_id,4};
        %         strat=src.Data{row_id,5};
        %         trans=src.Data{row_id,6};
        st = src.Data{row_id,10};
        %         et=src.Data{row_id,11};
        %         comm=src.Data{row_id,9};
        new_val = src.Data{row_id,col_id};
        data_ori{idx_struct,col_id} = src.Data{row_id,col_id};
    otherwise
        return;
end

path_f = getappdata(surv_data_tab,'path_data');

db_file = fullfile(path_f,'echo_logbook.db');
if ~(exist(db_file,'file')==2)
    initialize_echo_logbook_dbfile(path_f,main_figure,0)
end

% surv_data_struct=import_survey_data_db(db_file);

if dbconn.IsReadOnly
    fprintf('Database file is readonly... Check file permissions\n');
    return;
end

% dbconn.fetch(sprintf('delete from logbook where Filename is "%s" and StartTime=%.0f',filename,st));
% dbconn.insert('logbook',{'Filename' 'Snapshot' 'Type' 'Stratum' 'Transect'  'StartTime' 'EndTime' 'Comment'},...
%     {filename snap type strat trans st et comm});

if isnumeric(new_val)
    fmt = '%d';
else
    fmt = '%s';
end

switch fields{col_id}
    case {'Type' 'Stratum' 'Comment'}
        fmt=['''' fmt ''''];
    otherwise
        
end

disp_perso(main_figure,'Updating Logbook');
sql_query = sprintf(['UPDATE logbook SET %s=' fmt ' WHERE Filename=''%s'' and StartTime=''%s'''],fields{col_id},new_val,filename,st);
dbconn.exec(sql_query);

setappdata(surv_data_tab,'data_ori',data_ori);
layers = get_esp3_prop('layers');
if ~isempty(layers)
    [idx_lay,found] = find_layer_idx_files(layers,filename);
    if found==1
        layers(idx_lay).add_survey_data_db();
    end
end

update_tree_layer_tab(main_figure);
display_survdata_lines(main_figure);
drawnow;

disp_perso(main_figure,'');
hide_status_bar(main_figure);

end




%%
function set_type_night_steam(src, ~,surv_data_tab,main_figure)

dbconn   = getappdata(surv_data_tab,'dbconn');

if dbconn.IsReadOnly
    fprintf('Database file is readonly... Check file permissions\n');
    return;
end

data_ori = getappdata(surv_data_tab,'data_ori');

% times in fractions of a day
% Night starts 8pm NZST, aka 8am UTC.
% Night ends 5am NZST, aka 5pm UTC.
night_starts_UTC = 8./24;
night_ends_UTC   = 17./24;

%path_f = getappdata(surv_data_tab,'path_data');
%db_file = fullfile(path_f,'echo_logbook.db');

disp_perso(main_figure,'Updating Logbook');

layers = get_esp3_prop('layers');

filename={};

for ii = 1:size(data_ori,1)
    
    lb_type = data_ori{ii,4};
    lb_start_time = datenum(data_ori{ii,10}) - fix(datenum(data_ori{ii,10}));
    lb_end_time   = datenum(data_ori{ii,11}) - fix(datenum(data_ori{ii,11}));
    
    if isempty(lb_type) && lb_start_time>=night_starts_UTC && lb_start_time<=night_ends_UTC && lb_end_time>=night_starts_UTC && lb_end_time<=night_ends_UTC
        % change type of this file
        
        st = data_ori{ii,10};
        filename_tmp = data_ori{ii,2};
        filename=union(filename,filename_tmp);
        sql_query = sprintf('UPDATE logbook SET Type=''Night Steam'' WHERE Filename=''%s'' and StartTime=''%s''',filename_tmp,st);
        dbconn.exec(sql_query);
        
        if ~isempty(layers)
            [idx_lay,found] = find_layer_idx_files(layers,filename);
            if found==1
                layers(idx_lay).add_survey_data_db();
            end
        end
        
        
        
    end
end
if ~isempty(filename)
    reload_logbook_fig(surv_data_tab,filename);
end

drawnow;

disp_perso(main_figure,'');
hide_status_bar(main_figure);

end





%%
function selection_callback(src,~,surv_data_tab)
surv_data_table=getappdata(surv_data_tab,'surv_data_table');
data_ori=getappdata(surv_data_tab,'data_ori');
data=get(surv_data_table.table_main,'Data');

switch src.Tag
    case 'se'
        data(:,1)={true};
    case 'de'
        data(:,1)={false};
    case 'inv'
        data(:,1)=cellfun(@(x)~x,data(:,1),'un',0);
    case 'high'
        idx_sel=surv_data_table.table_main.UserData.highlighted_idx;
        data(idx_sel,1)={true};
    case 'dehigh'
        idx_sel=surv_data_table.table_main.UserData.highlighted_idx;
        data(idx_sel,1)={false};
end
data_ori(cell2mat(data(:,12)),1)=data(:,1);

set(surv_data_table.table_main,'Data',data);
setappdata(surv_data_tab,'data_ori',data_ori);
end

%%
function open_files_callback(src,evt,surv_data_tab,main_figure,sel_or_high)
surv_data_table=getappdata(surv_data_tab,'surv_data_table');
data_ori=get(surv_data_table.table_main,'Data');

switch sel_or_high
    case 'sel'
        selected_files=unique(data_ori([data_ori{:,1}],2));
    case 'high'
        selected_files=unique(surv_data_table.table_main.UserData.highlighted_files);
end


path_f=getappdata(surv_data_tab,'path_data');
files=fullfile(path_f,selected_files);
layers=get_esp3_prop('layers');

dbconn=getappdata(surv_data_tab,'dbconn');
if ~isempty(layers)
    [old_files,lay_IDs]=layers.list_files_layers();
    idx_already_open=cellfun(@(x) any(strcmpi(x,old_files)),files);
    
    if any(idx_already_open)
        disp_perso(main_figure,sprintf('File %s already open in existing layer',files{idx_already_open}));
        files_open=files(idx_already_open);
        files(idx_already_open)=[];
    end
else
    idx_already_open=[];
end

idx_deleted= find(~cellfun(@(x) exist(x,'file')==2,files));

if ~isempty(idx_deleted)
    
    
    for i=idx_deleted
        fprintf('Removing %s from logbook... cannot find it anymore.\n',files{i});
        dbconn.exec(sprintf('delete from logbook where Filename is "%s"',selected_files{i}));
    end
    
    reload_logbook_fig(surv_data_tab,{});
    files(idx_deleted)=[];
end

if isempty(files)
    if any(idx_already_open)
        idx_open=find(strcmpi(files_open{end},old_files));
        [idx_lay,~]=find_layer_idx(layers,lay_IDs{idx_open(end)});
        set_current_layer(layers(idx_lay));
        loadEcho(main_figure);
        hide_status_bar(main_figure);
        return;
    end
end

open_file([],[],files,main_figure);
load_bar_comp=getappdata(main_figure,'Loading_bar');



end

%%
function generate_xml_callback(~,~,surv_data_tab,main_figure)
surv_data_table=getappdata(surv_data_tab,'surv_data_table');
path_f=getappdata(surv_data_tab,'path_data');

surv_data_struct=get_struct_from_db(path_f);
data_ori=get(surv_data_table.table_main,'Data');
path_f=getappdata(surv_data_tab,'path_data');
idx_struct=unique([data_ori{[data_ori{:,1}],12}]);

survey_input_obj=survey_input_cl();

if isempty(idx_struct)
    return;
end

survey_input_obj.Infos.SurveyName=surv_data_struct.SurveyName{idx_struct(1)};
survey_input_obj.Infos.Voyage=surv_data_struct.Voyage{idx_struct(1)};
surv_data_struct.Folder=cell(size(surv_data_struct.Snapshot));
surv_data_struct.Folder(:)={path_f};
survey_input_obj.complete_survey_input_cl_from_struct(surv_data_struct,idx_struct,[],[]);
create_xml_script_gui('main_figure',main_figure,'survey_input_obj',survey_input_obj,'logbook_file',path_f);


%
% prompt={'Title',...
%     'Areas',...
%     'Author',...
%     'Main species',...
%     'Comments'};
%
% defaultanswer={'','','','',''};
%
% answer=inputdlg(prompt,'XML survey informations',[1;1;1;1;5],defaultanswer);
%
% if isempty(answer)
%     return;
% end
%
% survey_input_obj.Infos.Title=answer{1};
% survey_input_obj.Infos.Areas=answer{2};
% survey_input_obj.Infos.Author=answer{3};
% survey_input_obj.Infos.Main_species=answer{4};
% survey_input_obj.Infos.Comments=answer{5};
%
% if ~isfolder(path_scripts)
%     path_scripts=path_f;
% end
%
% [filename, pathname] = uiputfile('*.xml',...
%     'Save survey XML file',...
%     fullfile(path_scripts,[survey_input_obj.Infos.Voyage '.xml']));
%
% if isequal(filename,0) || isequal(pathname,0)
%     return;
% end
% survey_input_obj.check_n_complete_input();
%
%
% survey_input_obj.survey_input_to_survey_xml('xml_filename',fullfile(pathname,filename));

end


