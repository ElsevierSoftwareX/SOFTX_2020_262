function enter_new_trip_in_database(main_figure,db_file)
if isempty(db_file)
    db_folder= fullfile(whereisEcho(),'config','db');
    handles.db_file= fullfile(db_folder,'ac_db.db');
else
    handles.db_file=db_file;
end

if~isfile(handles.db_file)
    create_ac_database(handles.db_file,1);
end

size_max = get(0,'ScreenSize');

db_fig=new_echo_figure(main_figure,'Resize','on',...
    'Position',[0 0 size_max(3)*0.95 size_max(4)*0.8],'Name','Database loading tool','tag','ac_db_tool');

main_menu_db.m_files = uimenu(db_fig,'Label','File(s)');

%uimenu(m_files,'Label','Save current db_file','Callback',{@save_init_db,db_fig});
uimenu(main_menu_db.m_files,'Label','Create empty db file','Callback',{@create_empty_db_file_cback,db_fig});
uimenu(main_menu_db.m_files,'Label','Import db file from ESP3 database','Callback',{@import_other_db_cback,db_fig,'esp3'});
uimenu(main_menu_db.m_files,'Label','Import another initial db_file','Callback',@load_db_file_cback);

setappdata(db_fig,'main_menu_db',main_menu_db);


% db_file='pgdb.niwa.local:acoustic_test:esp3';
dbconn=connect_to_db(handles.db_file);
ship_type_t=dbconn.fetch('SELECT * from t_ship_type');
platform_type=dbconn.fetch('SELECT * from t_platform_type');
transducer_location_type=dbconn.fetch('SELECT * from t_transducer_location_type');
transducer_orientation_type=dbconn.fetch('SELECT * from t_transducer_orientation_type');

if istable(ship_type_t)
    s_type=ship_type_t.ship_type';
elseif iscell(ship_type_t)
    s_type=ship_type_t(:,2)';
end

if istable(platform_type)
    pt=platform_type.platform_type';
elseif iscell(platform_type)
    pt=platform_type(:,2)';
end

if istable(transducer_location_type)
    tlt=transducer_location_type.transducer_location_type';
elseif iscell(transducer_location_type)
    tlt=transducer_location_type(:,2)';
end


if istable(transducer_orientation_type)
    tot= transducer_orientation_type.transducer_orientation_type';
elseif iscell(transducer_orientation_type)
    tot=transducer_orientation_type(:,2)';
end

dbconn.close();

mission_col_fmt={'logical' 'numeric' 'char' 'char' 'char' 'char' 'char' 'char' 'char' 'char' 'char' 'char' 'char' 'char' 'char'};

mission_colnames={...
    'edit',...
    'mission_pkey',...
    'mission_name',...
    'mission_abstract',...
    'mission_start_date',...
    'mission_end_date',...
    'principal_investigator'...
    'principal_investigator_email',...
    'institution',...
    'data_centre',...
    'data_centre_email',...
    'mission_id',...
    'creator',...
    'contributor'...
    'mission_comments'...
    };

ship_col_fmt={'logical' 'numeric' 'char' s_type 'char' 'char' 'char' 'char' 'char' 'char' 'char' 'numeric' 'numeric' 'numeric' 'numeric' 'numeric' 'char' 'char' 'char'};
empty_ship_data={true 1 '' s_type{1} '' '' '' '' '' '' '' 0 0 0 0 0 '' '' ''};

ship_colnames={...
    'edit'               ,...
    'ship_pkey'          ,...
    'ship_name'          ,...
    'ship_type'          ,...
    'ship_code'          ,...
    'ship_platform_code' ,...
    'ship_platform_class',...
    'ship_callsign'      ,...
    'ship_alt_callsign'  ,...
    'ship_IMO'           ,...
    'ship_operator'      ,...
    'ship_length'        ,...
    'ship_breadth'       ,...
    'ship_draft'         ,...
    'ship_tonnage'       ,...
    'ship_engine_power'  ,...
    'ship_noise_design'  ,...
    'ship_aknowledgement',...
    'ship_comments'      ,...
    };


deployment_col_fmt={'logical' 'numeric' {'---'} {'---'} 'char' 'char' 'char' 'char' 'char' 'char' 'char' 'char' 'char' 'char' 'char'};

deployment_colnames={...
    'edit'               ,...
    'deployment_pkey'        ,...
    'deployment_type'        ,...
    'deployment_ship'        ,...
    'deployment_name'            ,...
    'deployment_id'              ,...
    'deployment_description'     ,...
    'deployment_area_description',...
    'deployment_operator'        ,...
    'deployment_summary_report'  ,...
    'deployment_start_date'      ,...
    'deployment_end_date'        ,...
    'deployment_start_port'      ,...
    'deployment_end_port'        ,...
    'deployment_comments'        ,...
    };

load_loading_bar_panel_v2(db_fig);
load_bar_comp=getappdata(db_fig,'Loading_bar');
pos_init=load_bar_comp.panel.Position;
set(load_bar_comp.panel,'Units','norm');
pos_main=getpixelposition(db_fig);
pos_main(4)=pos_main(4)-pos_init(4);

mission_panel=uipanel(db_fig,'units','pixels','Position',[0 3*pos_main(4)/4+pos_init(4) pos_main(3) pos_main(4)/4],'title','Mission','BackgroundColor','white');
m_panel_pos=mission_panel.Position;
set(mission_panel,'units','norm');

handles.mission_table = uitable('Parent',mission_panel,...
    'Data',[],...
    'ColumnName',mission_colnames,...
    'ColumnFormat',mission_col_fmt,...
    'ColumnEditable',true,...
    'CellEditCallBack',{@cell_edit_cback,db_fig},...
    'CellSelectionCallback',@cell_select_cback,...
    'RowName',[],...
    'Position',[0 0 m_panel_pos(3) m_panel_pos(4)*0.90],...
    'Tag','t_mission');
handles.mission_table.UserData.select=[];
%set(mission_panel,'units','norm','SizeChangedFcn',@resize_table);
set(handles.mission_table,'units','norm');

set_auto_resize_table(handles.mission_table);

ship_panel=uipanel(db_fig,'units','pixels','Position',[0 1*pos_main(4)/4+pos_init(4) pos_main(3) pos_main(4)/4],'title','Ship','BackgroundColor','white');
s_panel_pos=ship_panel.Position;
set(ship_panel,'units','norm');


handles.ship_table = uitable('Parent',ship_panel,...
    'Data',[],...
    'ColumnName', ship_colnames,...
    'ColumnFormat',ship_col_fmt,...
    'ColumnEditable',true,...
    'CellEditCallBack',{@cell_edit_cback,db_fig},...
    'CellSelectionCallback',@cell_select_cback,...
    'RowName',[],...
    'Position',[0 0 s_panel_pos(3) s_panel_pos(4)*0.9],...
    'Tag','t_ship');
%set(ship_panel,'units','norm','SizeChangedFcn',@resize_table);
set(handles.ship_table,'units','norm');

set_auto_resize_table(handles.ship_table);

handles.ship_table.UserData.empty_data=empty_ship_data;
handles.ship_table.UserData.select=[];

deployment_panel=uipanel(db_fig,'units','pixels','Position',[0 2*pos_main(4)/4+pos_init(4) pos_main(3) pos_main(4)/4],'title','Deployment','BackgroundColor','white');
d_panel_pos=deployment_panel.Position;
set(deployment_panel,'units','norm');


handles.deployment_table = uitable('Parent',deployment_panel,...
    'Data',[],...
    'ColumnName',deployment_colnames,...
    'ColumnFormat',deployment_col_fmt,...
    'ColumnEditable',true,...
    'CellEditCallBack',{@cell_edit_cback,db_fig},...
    'CellSelectionCallback',@cell_select_cback,...
    'RowName',[],...
    'Position',[0 0 d_panel_pos(3) d_panel_pos(4)*0.90],...
    'Tag','t_deployment');
handles.deployment_table.UserData.select=[];
%set(deployment_panel,'units','norm','SizeChangedFcn',@resize_table);
set(handles.deployment_table,'units','norm');

set_auto_resize_table(handles.ship_table);


create_table_txt_menu([handles.mission_table handles.ship_table handles.deployment_table])

% set_multi_select(ship_table,0);
% set_multi_select(mission_table,0);
% set_multi_select(deployment_table,0);

add_panel=uipanel(db_fig,'units','pixels','Position',[0 0*pos_main(4)/4+pos_init(4) pos_main(3) pos_main(4)/4],'title','Database creation','BackgroundColor','white');
add_panel.Units='Characters';
a_panel_pos=add_panel.Position;
gui_fmt=init_gui_fmt_struct();
gui_fmt.txt_w=gui_fmt.txt_w*2;
gui_fmt.box_w=gui_fmt.box_w*2;
uicontrol(add_panel,gui_fmt.txtTitleStyle,'position',[2 a_panel_pos(4)*0.8 gui_fmt.txt_w a_panel_pos(4)*0.1],'string','Mission');
handles.mission_pop=uicontrol(add_panel,gui_fmt.lstboxStyle,'position',[2 a_panel_pos(4)*0.10 gui_fmt.txt_w a_panel_pos(4)*0.7],'string','--','min',0,'max',0);
uicontrol(add_panel,gui_fmt.txtTitleStyle,'position',[gui_fmt.txt_w+4 a_panel_pos(4)*0.8 gui_fmt.txt_w a_panel_pos(4)*0.1],'string','Deployment');
handles.deployment_pop=uicontrol(add_panel,gui_fmt.lstboxStyle,'position',[gui_fmt.txt_w+4 a_panel_pos(4)*0.10 gui_fmt.txt_w a_panel_pos(4)*0.7],'string','--','min',0,'max',0);

app_path_main=whereisEcho();
icon=get_icons_cdata(fullfile(app_path_main,'icons'));


uicontrol(add_panel,gui_fmt.txtStyle,...
    'Position',[2*gui_fmt.txt_w+8 a_panel_pos(4)*0.80 gui_fmt.txt_w a_panel_pos(4)*0.1],...
    'string','Input Data Folder',...
    'HorizontalAlignment','left');

handles.path_edit = uicontrol(add_panel,gui_fmt.edtStyle,...
    'Position',[2*gui_fmt.txt_w+8 a_panel_pos(4)*0.70 gui_fmt.txt_w a_panel_pos(4)*0.1],...
    'BackgroundColor','w',...
    'string','',...
    'HorizontalAlignment','left');

handles.path_button=uicontrol(add_panel,gui_fmt.pushbtnStyle,...
    'Position',[3*gui_fmt.txt_w+8 a_panel_pos(4)*0.70 gui_fmt.box_w a_panel_pos(4)*0.1],...
    'Cdata',icon.folder,...
    'callback',{@select_folder_callback,handles.path_edit});

handles.add_button=uicontrol(add_panel,gui_fmt.pushbtnStyle,...
    'Position',[3*gui_fmt.txt_w+8+gui_fmt.box_w a_panel_pos(4)*0.70 gui_fmt.box_w a_panel_pos(4)*0.1],...
    'String','Add',...
    'callback',{@add_folder_callback,db_fig});

handles.summary_table = uitable('Parent',add_panel,...
    'Data',[],...
    'ColumnName',{'------Input Data folder------' 'Mission PKEY' 'Deploy. PKEY' 'Deploy. ID' 'Platform Type' 'Transd. Location' 'Trand. Orientation'},...
    'ColumnFormat',{'char' 'numeric' 'numeric' 'char' pt tlt tot},...
    'ColumnEditable',[false false false false true true true],...
    'CellSelectionCallback',@cell_select_cback,...
    'RowName',[],...
    'Units','Characters',...
    'Position',[2*gui_fmt.txt_w+8 a_panel_pos(4)*0.10 gui_fmt.txt_w*2+gui_fmt.box_w*3+2 a_panel_pos(4)*0.6],...
    'Tag','t_deployment');
handles.summary_table.UserData.select=[];



rc_menu = uicontextmenu(ancestor(handles.summary_table,'figure'));
uimenu(rc_menu,'Label','Remove','Callback',{@rm_folder_cback,handles.summary_table});
handles.summary_table.UIContextMenu =rc_menu;

uicontrol(add_panel,gui_fmt.txtStyle,...
    'Position',[3*gui_fmt.txt_w+10+gui_fmt.box_w*2 a_panel_pos(4)*0.80 gui_fmt.txt_w a_panel_pos(4)*0.1],...
    'string','Ouput MINIDB file',...
    'HorizontalAlignment','left');

handles.sqlite_schema = uicontrol(add_panel,gui_fmt.edtStyle,...
    'Position',[3*gui_fmt.txt_w+10+gui_fmt.box_w*2 a_panel_pos(4)*0.70 gui_fmt.txt_w a_panel_pos(4)*0.1],...
    'string','',...
    'Enable','off',...
    'HorizontalAlignment','left');

uicontrol(add_panel,gui_fmt.pushbtnStyle,...
    'Position',[4*gui_fmt.txt_w+10+gui_fmt.box_w*2 a_panel_pos(4)*0.70 gui_fmt.box_w a_panel_pos(4)*0.1],...
    'Cdata',icon.folder,...
    'BackgroundColor','white','callback',{@choose_output_file,db_fig});

uicontrol(add_panel,gui_fmt.pushbtnStyle,...
    'Position',[4*gui_fmt.txt_w+12+gui_fmt.box_w*3 a_panel_pos(4)*0.70 gui_fmt.box_w*4 a_panel_pos(4)*0.1],...
    'String','Generate MINIDB',...
    'callback',{@generate_db_cback,db_fig});

handles.sqlite_table = uitable('Parent',add_panel,...
    'Data',[],...
    'ColumnName',{'Mission' 'Deploy' 'ID'},...
    'ColumnFormat',{'char' 'char' 'char'},...
    'ColumnEditable',[false false false],...
    'CellSelectionCallback',@cell_select_cback,...
    'RowName',[],...
    'Units','Characters',...
    'Position',[4*gui_fmt.txt_w+12+gui_fmt.box_w*3 a_panel_pos(4)*0.10 gui_fmt.box_w*4 a_panel_pos(4)*0.6],...
    'Tag','sqlite');
% handles.sqlite_table.ColumnWidth='auto';
handles.sqlite_table.UserData.select=[];



uicontrol(add_panel,gui_fmt.txtStyle,...
    'Position',[4*gui_fmt.txt_w+14+gui_fmt.box_w*7 a_panel_pos(4)*0.80 gui_fmt.box_w*5 a_panel_pos(4)*0.1],...
    'string','Loading to Database process',...
    'HorizontalAlignment','left');

handles.load_bttn=uicontrol(add_panel,gui_fmt.pushbtnStyle,...
    'Position',[4*gui_fmt.txt_w+14+gui_fmt.box_w*7 a_panel_pos(4)*0.70 gui_fmt.box_w*3 a_panel_pos(4)*0.1],...
    'String','Load to LOAD schema',...
    'Enable','off',...
    'callback',{@load_to_db_cback,db_fig,'load'});


handles.load_schema = uicontrol(add_panel,gui_fmt.edtStyle,...
    'Position',[4*gui_fmt.txt_w+14+gui_fmt.box_w*7 a_panel_pos(4)*0.60 gui_fmt.box_w*3 a_panel_pos(4)*0.1],...
    'string','wellfisheriesdb:acoustic:load',...
    'HorizontalAlignment','left',...
    'callback',{@check_connection_cback,db_fig,'load'});

handles.load_table = uitable('Parent',add_panel,...
    'Data',[],...
    'ColumnName',{'Mission' 'Deploy' 'ID'},...
    'ColumnFormat',{'char' 'char' 'char'},...
    'ColumnEditable',[false false false],...
    'CellSelectionCallback',@cell_select_cback,...
    'RowName',[],...
    'Units','Characters',...
    'Position',[4*gui_fmt.txt_w+14+gui_fmt.box_w*7 a_panel_pos(4)*0.10 gui_fmt.box_w*3 a_panel_pos(4)*0.5],...
    'Tag','load');
handles.load_table.UserData.select=[];

set_auto_resize_table(handles.load_table);


handles.esp3_bttn=uicontrol(add_panel,gui_fmt.pushbtnStyle,...
    'Position',[4*gui_fmt.txt_w+14+gui_fmt.box_w*10 a_panel_pos(4)*0.70 gui_fmt.box_w*3 a_panel_pos(4)*0.1],...
    'String','Load to ESP3 schema',...
    'Enable','off',...
    'callback',{@load_to_db_cback,db_fig,'esp3'});

handles.esp3_schema = uicontrol(add_panel,gui_fmt.edtStyle,...
    'Position',[4*gui_fmt.txt_w+14+gui_fmt.box_w*10 a_panel_pos(4)*0.60 gui_fmt.box_w*3 a_panel_pos(4)*0.1],...
    'string','wellfisheriesdb:acoustic:esp3',...
    'HorizontalAlignment','left',...
    'callback',{@check_connection_cback,db_fig,'esp3'});

handles.esp3_table = uitable('Parent',add_panel,...
    'Data',[],...
    'ColumnName',{'Mission' 'Deploy' 'ID'},...
    'ColumnFormat',{'char' 'char' 'char'},...
    'ColumnEditable',[false false false],...
    'CellSelectionCallback',@cell_select_cback,...
    'RowName',[],...
    'Units','Characters',...
    'Position',[4*gui_fmt.txt_w+14+gui_fmt.box_w*10 a_panel_pos(4)*0.10 gui_fmt.box_w*3 a_panel_pos(4)*0.5],...
    'Tag','esp3');
handles.load_table.UserData.select=[];

set(add_panel,'units','norm');
set_auto_resize_table(handles.esp3_table);

setappdata(db_fig,'handles',handles);

check_connection_cback(handles.load_schema,[],db_fig,'load');
check_connection_cback(handles.esp3_schema,[],db_fig,'esp3');

create_table_db_menu([handles.sqlite_table handles.load_table handles.sqlite_table handles.esp3_table]);

update_data_tables(db_fig);
drawnow;


end

function  load_db_file_cback(src,evt)
db_fig=ancestor(src,'figure');
handles=getappdata(db_fig,'handles');

db_file_ori=handles.db_file;
folder_ori=fileparts(db_file_ori);

[filename, pathname] = uigetfile('*.db',...
    'Output .db file',...
    folder_ori);
if isequal(filename,0) || isequal(pathname,0)
    return;
end
import_other_db_cback([],[],db_fig,fullfile(pathname,filename));

end

function import_other_db_cback(src,evt,db_fig,str_db)

handles=getappdata(db_fig,'handles');

switch str_db
    case 'esp3'
       new_ac_db_file=retrieve_ac_db_from_other_db(handles.esp3_schema.String);
    otherwise
      new_ac_db_file=str_db;
end


if ~isempty(new_ac_db_file)
   [folder,~,~]=fileparts(handles.db_file);
   old_ac_db_dest=fullfile(folder,sprintf('ac_db%s.db',datestr(now,'HHMMSS_ddmmyyyy')));
   new_ac_db_dest=fullfile(folder,'ac_db.db');
   copyfile(handles.db_file,old_ac_db_dest,'f');
   copyfile(new_ac_db_file,new_ac_db_dest,'f');
   
   
   handles.summary_table.Data=[];
   setappdata(db_fig,'handles',handles);
   update_data_tables(db_fig);
   update_str(db_fig,'mission');
   update_str(db_fig,'deployment');
   update_data_tables(db_fig);   
   
   warndlg_perso([],'Sucess',sprintf('Data imported from %s. Old database saved as %s',handles.esp3_schema.String,old_ac_db_dest));
else
    warndlg_perso([],'Failed',sprintf('Could not import data from %s',handles.esp3_schema.String));
end


end

function new_ac_db_file=retrieve_ac_db_from_other_db(db_to_copy)
new_ac_db_file=fullfile(tempdir,'ac_db.db');
create_ac_database(new_ac_db_file,1);

dbconn=connect_to_db(db_to_copy);
if isempty(dbconn)
    delete(new_ac_db_file);
    new_ac_db_file=[];
    return;
end
mission_t=dbconn.fetch('SELECT * from t_mission ORDER BY mission_start_date');
deployment_t=dbconn.fetch('SELECT * from t_deployment ORDER BY deployment_start_date');
ship_t=dbconn.fetch('SELECT * from t_ship');
deployment_type_t=dbconn.fetch('SELECT * from t_deployment_type');
ship_type_t=dbconn.fetch('SELECT * from t_ship_type');
dbconn.close();
d_struct=table2struct(deployment_t,'ToScalar',true);
m_struct=table2struct(mission_t,'ToScalar',true);
dbconn=connect_to_db(new_ac_db_file);

add_mission_struct_to_t_mission(dbconn,'mission_struct',m_struct);
%dbconn.insert('t_mission',mission_t.Properties.VariableNames,mission_t);
add_deployment_struct_to_t_deployment(dbconn,'deployment_struct',d_struct);
%dbconn.insert('t_deployment',deployment_t.Properties.VariableNames,deployment_t);
dbconn.insert('t_ship',ship_t.Properties.VariableNames,ship_t);
dbconn.exec('DELETE from t_deployment_type');
dbconn.insert('t_deployment_type',deployment_type_t.Properties.VariableNames,deployment_type_t);
dbconn.exec('DELETE from t_ship_type');
dbconn.insert('t_ship_type',ship_type_t.Properties.VariableNames,ship_type_t);

dbconn.close();





end

function update_data_tables(db_fig)
handles=getappdata(db_fig,'handles');

if~isfile(handles.db_file)
    create_ac_database(handles.db_file,1);
end

db_file=handles.db_file;
%db_file='pgdb.niwa.local:acoustic_test:esp3';

dbconn=connect_to_db(db_file);

mission_t=dbconn.fetch('SELECT * FROM t_mission ORDER BY mission_start_date DESC');
deployment_t=dbconn.fetch('SELECT * FROM t_deployment ORDER BY deployment_start_date DESC');
ship_t=dbconn.fetch('SELECT * FROM t_ship');
deployment_type_t=dbconn.fetch('SELECT * FROM t_deployment_type');
ship_type_t=dbconn.fetch('SELECT * FROM t_ship_type');
dbconn.close();

if~isempty(mission_t)
    %mission_t.mission_pkey=[];
    data_mission=table2cell(mission_t);
    data_mission=[num2cell(false(1,size(data_mission,1)));data_mission']';
else
    data_mission=[];
end
handles.mission_table.UserData.select=[];
handles.mission_table.Data=data_mission;

if~isempty(ship_t)
    ship_t.ship_type_key = ship_type_t.ship_type(ship_t.ship_type_key);
    ship_t.Properties.VariableNames(strcmp(ship_t.Properties.VariableNames,'ship_type_key'))={'ship_type'};
    data_ship=table2cell(ship_t);
    data_ship=[num2cell(false(1,size(data_ship,1)));data_ship']';
else
    data_ship=[];
end
handles.ship_table.UserData.select=[];
handles.ship_table.Data=data_ship;

if~isempty(deployment_t)
    id_type=nan(1,numel(deployment_t.deployment_type_key));
    id_ship=nan(1,numel(deployment_t.deployment_type_key));
    
    for id=1:numel(deployment_t.deployment_ship_key)
        id_type(id)=find(deployment_t.deployment_type_key(id)==deployment_type_t.deployment_type_pkey);
        id_ship(id)=find(ship_t.ship_pkey==deployment_t.deployment_ship_key(id));
    end
    
    deployment_t.deployment_type_key=cell(numel(deployment_t.deployment_type_key),1);
    deployment_t.deployment_ship_key=cell(numel(deployment_t.deployment_type_key),1);
    
    deployment_t.deployment_type_key = deployment_type_t.deployment_type(id_type);
    deployment_t.deployment_ship_key = ship_t.ship_name(id_ship);
    
    deployment_t.Properties.VariableNames(strcmp(deployment_t.Properties.VariableNames,'deployment_type_key'))={'deployment_type'};
    deployment_t.Properties.VariableNames(strcmp(deployment_t.Properties.VariableNames,'deployment_ship_key'))={'deployment_ship'};
    deployment_t.deployment_northlimit=[];
    deployment_t.deployment_eastlimit=[];
    deployment_t.deployment_southlimit=[];
    deployment_t.deployment_westlimit=[];
    deployment_t.deployment_uplimit=[];
    deployment_t.deployment_downlimit=[];
    deployment_t.deployment_units=[];
    deployment_t.deployment_zunits=[];
    deployment_t.deployment_projection=[];
    
    if any(contains(deployment_t.Properties.VariableNames,'deployment_start_BODC_code'))
        deployment_t.deployment_start_BODC_code=[];
        deployment_t.deployment_end_BODC_code=[];
    else
        deployment_t.deployment_start_bodc_code=[];
        deployment_t.deployment_end_bodc_code=[];
    end
    data_deployment=table2cell(deployment_t);
    data_deployment=[num2cell(false(1,size(data_deployment,1)));data_deployment']';
else
    data_deployment=[];
end
handles.deployment_table.UserData.select=[];
handles.deployment_table.Data=data_deployment;
handles.deployment_table.ColumnFormat={'logical' 'numeric' deployment_type_t.deployment_type' {'---'} 'char' 'char' 'char' 'char' 'char' 'char' 'char' 'char' 'char' 'char' 'char'};

if ~isempty(handles.ship_table.Data)
    handles.deployment_table.ColumnFormat(contains(handles.deployment_table.ColumnName,'deployment_ship'))={unique(handles.ship_table.Data(:,3))'};
end

update_str(db_fig,'mission');
update_str(db_fig,'deployment');

end


function update_db_tables(db_fig,schema)
handles=getappdata(db_fig,'handles');
for i=1:numel(schema)
    try
        if strcmpi(schema{i},'sqlite')
            if ~isfile(handles.([schema{i} '_schema']).String)
                return;
            end
        end
        
        dbconn=connect_to_db(handles.([schema{i} '_schema']).String);
        sql_query=['SELECT m.mission_name,'...
            'd.deployment_name, '...
            'd.deployment_id '...
            'FROM t_mission m,'...
            't_deployment d,'...
            't_mission_deployment md '...
            'WHERE m.mission_pkey=md.mission_key '...
            'AND d.deployment_pkey=md.deployment_key ORDER BY m.mission_start_date DESC;'];
        data=dbconn.fetch(sql_query);
        dbconn.close();
        if istable(data)
            data=table2cell(data);
        end
        
    catch
        data=[];
    end
    handles.([schema{i} '_table']).Data=data;
end
end


function check_connection_cback(src,evt,db_fig,schema)
handles=getappdata(db_fig,'handles');

try
    dbconn=connect_to_db(src.String);
catch
    dbconn=[];
end

if isempty(dbconn)
    state='off';
    col=[0.8 0 0];
else
    col=[0 0.8 0];
    state='on';
    dbconn.close();
end

switch schema
    case 'load'
        he=handles.load_schema;
        hb=handles.load_bttn;
        
    case 'esp3'
        he=handles.esp3_schema;
        hb=handles.esp3_bttn;
end

hb.Enable=state;
set(he,'BackgroundColor',col);
update_db_tables(db_fig,{schema});
end

function load_to_db_cback(~,~,db_fig,schema)

% get handles for database source and destination
handles = getappdata(db_fig,'handles');

switch schema
    case 'load'
        db_source = handles.sqlite_schema.String;
        db_dest   = handles.load_schema.String;
        bck_and_rem = 0;
        clear_dest  = 1;
    case 'esp3'
        db_source = handles.load_schema.String;
        db_dest   = handles.esp3_schema.String;
        bck_and_rem = 1;
        clear_dest = 0;
    otherwise
        return;
end

% transfer source to destination
transfer_ac_database(db_source,db_dest,'clear_dest',clear_dest,'backup_and_remove_src',bck_and_rem);

% update GUI tables
update_db_tables(db_fig,{'sqlite' 'load' 'esp3'});

end

function save_init_db(src,evt,db_fig)
disp('Saving init_db file...');

end

function  generate_db_cback(src,evt,db_fig)

handles = getappdata(db_fig,'handles');
summary_data = handles.summary_table.Data;
database_filename = handles.sqlite_schema.String;

if ~isempty(summary_data)
        
    dbconn = connect_to_db(handles.db_file);
    %     ship_type_t=dbconn.fetch('SELECT * FROM t_ship_type');
    %     deployment_type_t=dbconn.fetch('SELECT * FROM t_deployment_type');
    
    deployment_t = dbconn.fetch('SELECT * FROM t_deployment');
    mission_t = dbconn.fetch('SELECT * FROM t_mission');
    ship_t = dbconn.fetch('SELECT * FROM t_ship');
    
    dbconn.close();
    
    deployment_struct = table2struct(deployment_t,'ToScalar',true);
    mission_struct    = table2struct(mission_t,'ToScalar',true);
    ship_struct       = table2struct(ship_t,'ToScalar',true);
    
    if ~isempty(database_filename)
        
        create_ac_database(database_filename,1);
        
        ship_pkeys = add_ship_struct_to_t_ship(database_filename,'ship_struct',ship_struct);
        
        % number of data folders
        nb_f = size(summary_data,1);
        
        for ifi = 1:nb_f
            
            % getting mission and deployment pkeys FROM summary_data
            idx_mission    = find(mission_struct.mission_pkey==[summary_data{ifi,2}]);
            idx_deployment = find(deployment_struct.deployment_pkey==[summary_data{ifi,3}]);
            
            % see if database already has this mission in it
            [~,mission_pkey] = get_cols_from_table(database_filename,'t_mission','input_struct',mission_struct,'output_cols',{'mission_pkey'},'row_idx',idx_mission);
            
            if isempty(mission_pkey)
                % if not, insert it
                datainsert_perso(database_filename,'t_mission',mission_struct,'idx_insert',idx_mission);
                [~,mission_pkey] = get_cols_from_table(database_filename,'t_mission','input_struct',mission_struct,'output_cols',{'mission_pkey'},'row_idx',idx_mission);
            end
            
            % see if database already has this deployment in it
            %[~,deployment_pkey,SQL_query] = get_cols_from_table(database_filename,'t_deployment','input_struct',deployment_struct,'output_cols',{'deployment_pkey'},'row_idx',idx_deployment);
            [~,deployment_pkey,SQL_query] = get_cols_from_table(database_filename,'t_deployment',...
                'input_cols',{'deployment_id'},'input_vals',deployment_struct.deployment_id(idx_deployment),'output_cols',{'deployment_pkey'});
            
            if isempty(deployment_pkey)
                % if not, insert it
                datainsert_perso(database_filename,'t_deployment',deployment_struct,'idx_insert',idx_deployment);
                %[~,deployment_pkey] = get_cols_from_table(database_filename,'t_deployment','input_struct',deployment_struct,'output_cols',{'deployment_pkey'},'row_idx',idx_deployment);
                [~,deployment_pkey,SQL_query] = get_cols_from_table(database_filename,'t_deployment',...
                    'input_cols',{'deployment_id'},'input_vals',deployment_struct.deployment_id(idx_deployment),'output_cols',{'deployment_pkey'});
            end
            
            populate_ac_db_from_folder(db_fig,summary_data{ifi,1},...
                'ac_db_filename',database_filename,...
                'mission_pkey',mission_pkey{1,1},...
                'deployment_pkey',deployment_pkey{1,1},...
                'platform_type',summary_data{ifi,5},...
                'transducer_location_type',summary_data{ifi,6},...
                'transducer_orientation_type',summary_data{ifi,7},...
                'overwrite_db',0,...
                'populate_t_navigation',1);
            
        end
    else
        warning('Output not defined.')
    end
end
save_init_db(src,evt,db_fig);
update_db_tables(db_fig,{'sqlite'});
end

function create_empty_db_file_cback(src,evt,db_fig)
handles=getappdata(db_fig,'handles');
folder=fileparts(handles.db_file);
f_def=fullfile(folder,'empty_ac_db.db');
[filename, pathname] = uiputfile('*.db',...
    'Output .db file',...
    f_def);
if isequal(filename,0) || isequal(pathname,0)
    return;
end
create_ac_database(fullfile(pathname,filename),1);
end

function choose_output_file(src,evt,db_fig)
handles=getappdata(db_fig,'handles');
folder=get(handles.path_edit,'string');
out_file=get(handles.sqlite_schema,'string');

if isfile(out_file)
    folder=fileparts(out_file);
end
if ~isfolder(folder)
    folder=pwd;
end

data_deployment=handles.deployment_table.Data;
data_summary=handles.summary_table.Data;
if ~isempty(data_deployment)&&~isempty(data_summary)
    idx=(ismember([data_deployment{:,2}],[data_summary{:,3}]));
    deploy_id=data_deployment(idx,6);
    f_def=fullfile(folder,sprintf('%s_ac_db.db',strjoin(deploy_id,'_')));
else
    f_def=fullfile(folder,'ac_db.db');
end

[filename, pathname] = uiputfile('*.db',...
    'Output .db file',...
    f_def);
if isequal(filename,0) || isequal(pathname,0)
    return;
end
set(handles.sqlite_schema,'string',fullfile(pathname,filename));
update_db_tables(db_fig,{'sqlite'});
end

function add_folder_callback(~,~,db_fig)
handles=getappdata(db_fig,'handles');
folder=get(handles.path_edit,'string');
data_mission=handles.mission_table.Data;
data_deployment=handles.deployment_table.Data;

if isfolder(folder)&&~isempty(data_mission)&&~isempty(data_deployment)
    mission_idx=get(handles.mission_pop,'value');
    deployment_idx=get(handles.deployment_pop,'value');
    data_add={folder data_mission{mission_idx,2} data_deployment{deployment_idx,2} data_deployment{deployment_idx,6} '' '' ''};
    handles.summary_table.Data=table2cell(unique(cell2table([handles.summary_table.Data;data_add])));
end

end

function select_folder_callback(~,~,edit_box)

path_ori=get(edit_box,'string');
if ~isfolder(path_ori)
    path_ori=pwd;
end
new_path = uigetdir(path_ori);
if new_path~=0
    set(edit_box,'string',new_path);
end

end

function rm_folder_cback(src,evt,tb)
if ~isempty(tb.Data)&&~isempty(tb.UserData.select)
    tb.Data(tb.UserData.select(:,1),:)=[];
end
end

function create_table_txt_menu(tb)

for i=1:numel(tb)
    rc_menu = uicontextmenu(ancestor(tb(i),'figure'));
    uimenu(rc_menu,'Label','Add entry','Callback',{@add_entry_cback,tb(i)});
    uimenu(rc_menu,'Label','Remove entry(ies)','Callback',{@rm_entry_cback,tb(i)});
    tb(i).UIContextMenu =rc_menu;
end
end

function create_table_db_menu(tb)
for i=1:numel(tb)
    rc_menu = uicontextmenu(ancestor(tb(i),'figure'));
    uimenu(rc_menu,'Label','Edit/View Setups','Callback',{@edit_setup_cback,tb(i)});
    %uimenu(rc_menu,'Label','Edit/Add calibration','Callback',{@edit_cal_cback,tb(i)});
    tb(i).UIContextMenu =rc_menu;
end
end

function edit_setup_cback(src,evt,tb)
db_fig=ancestor(src,'figure');
if ~isfield(tb.UserData,'select')
    return;
end
if ~isempty(tb.Data)&&~isempty(tb.UserData.select)
    idx=tb.UserData.select(end,1);
    handles=getappdata(db_fig,'handles');
    dbconn=connect_to_db(handles.([tb.Tag '_schema']).String);
    switch tb.Tag
        case 'sqlite'
            dbtab='';
        otherwise
            dbtab=[tb.Tag '.'];
    end
    
    sql_cmd=[...
        'SELECT DISTINCT '...
        'trsc.transceiver_manufacturer,'...
        'trsc.transceiver_model,'...
        'trsc.transceiver_serial,'...
        'trsd.transducer_manufacturer,'...
        'trsd.transducer_model,'...
        'trsd.transducer_serial'...
        ' FROM '...
        dbtab 't_setup s,'...
        dbtab 't_deployment d,'...
        dbtab 't_file f,'...
        dbtab 't_file_setup fs,'...
        dbtab 't_transceiver trsc,'...
        dbtab 't_transducer trsd'...
        ' WHERE '...
        'd.deployment_id=''' tb.Data{idx,3} ''' AND '...
        'f.file_pkey=fs.file_key AND s.setup_pkey=fs.setup_key AND '...
        'f.file_deployment_key=d.deployment_pkey AND '...
        's.setup_transceiver_key=trsc.transceiver_pkey AND '...
        's.setup_transducer_key=trsd.transducer_pkey'];
    data=dbconn.fetch(sql_cmd);
    dbconn.close()
    if istable(data)
        data_t=table2cell(data);
    else
        data_t=data;
    end
    col_names={'transceiver_manufacturer' 'transceiver_model' 'transceiver_serial' 'transducer_manufacturer' 'transducer_model' 'transducer_serial'};
    col_fmt={'char' 'char' 'char' 'char' 'char' 'char'};
    sub_db_fig=new_echo_figure([],'WindowStyle','modal','Resize','off','Position',[0 0 600 200],'Name',tb.Data{idx,3});
    uitable('Parent',sub_db_fig,...
        'Data',data_t,...
        'ColumnName',col_names,...
        'ColumnFormat',col_fmt,...
        'ColumnEditable',[true true true true true true],...
        'CellEditCallBack',{@setup_edit_cback,tb,db_fig},...
        'CellSelectionCallback',[],...
        'RowName',[],...
        'units','norm',...
        'Position',[0 0 1 1]);
    
end
end

function setup_edit_cback(src,evt,tb,db_fig)
handles=getappdata(db_fig,'handles');
idx_edit=evt.Indices;
data_edit=src.Data(idx_edit(1),:);
data_old=data_edit;

data_old{idx_edit(2)}=evt.PreviousData;
switch idx_edit(2)
    case {1,2,3}
        sql_cmd=sprintf('UPDATE t_transceiver SET transceiver_manufacturer=''%s'', transceiver_model=''%s'', transceiver_serial=''%s'' WHERE transceiver_manufacturer=''%s'' AND transceiver_model=''%s'' AND transceiver_serial=''%s''',...
            data_edit{1},data_edit{2},data_edit{3},data_old{1},data_old{2},data_old{3});
    case {4,5,6}
        sql_cmd=sprintf('UPDATE t_transducer SET transducer_manufacturer=''%s'', transducer_model=''%s'', transducer_serial=''%s'' WHERE transducer_manufacturer=''%s'' AND transducer_model=''%s'' AND transducer_serial=''%s''',...
            data_edit{4},data_edit{5},data_edit{6},data_old{4},data_old{5},data_old{6});
end

dbconn=connect_to_db(handles.([tb.Tag '_schema']).String);
out=dbconn.exec(sql_cmd);
dbconn.close();
end



function update_str(db_fig,tb_name)
handles=getappdata(db_fig,'handles');
data=handles.([tb_name '_table']).Data;
if isempty(data)
    str='--';
else
    str=data(:,contains(handles.([tb_name '_table']).ColumnName,([tb_name '_name'])));
end
set(handles.(([tb_name '_pop'])),'String',str,'Value',min(numel(str),handles.(([tb_name '_pop'])).Value));

end

function rm_entry_cback(src,evt,tb)
if ~isempty(tb.Data)&&~isempty(tb.UserData.select)
    db_fig=ancestor(tb,'figure');
    handles=getappdata(db_fig,'handles');
    switch tb.Tag
        case 't_deployment'
            p_key='deployment_pkey';
        case 't_mission'
            p_key='mission_pkey';
        case 't_ship'
            p_key='ship_pkey';
    end
    dbconn=connect_to_db(handles.db_file);
    for i=[tb.Data{tb.UserData.select(:,1),2}]
        sql_cmd=sprintf('DELETE FROM %s where %s=%d',tb.Tag,p_key,i);
        try
            dbconn.exec(sql_cmd);
        catch
            disp('Could not delete entry');
        end
    end
    dbconn.close();
    update_str(db_fig,'mission');
    update_str(db_fig,'deployment');
    update_data_tables(db_fig);
end

end

function add_entry_cback(src,evt,tb)
db_fig=ancestor(tb,'figure');
handles=getappdata(db_fig,'handles');

switch tb.Tag
    case 't_deployment'
        add_deployment_struct_to_t_deployment(handles.db_file);
    case 't_mission'
        add_mission_struct_to_t_mission(handles.db_file);
    case 't_ship'
        add_ship_struct_to_t_ship(handles.db_file);
end

update_str(db_fig,'mission');
update_str(db_fig,'deployment');
update_data_tables(db_fig);
end

function cell_select_cback(src,evt)
src.UserData.select=evt.Indices;
end

function cell_edit_cback(src,evt,db_fig)
handles=getappdata(db_fig,'handles');
colnames=src.ColumnName;
idx=evt.Indices;
row_id=idx(1);
colname=src.ColumnName{idx(2)};
if (src.Data{row_id,1}||idx(2)==1)
    pkey=src.Data{row_id,2};
    if ~iscell(src.ColumnFormat{idx(2)})
        switch src.ColumnFormat{idx(2)}
            case 'char'
                if contains(src.ColumnName{idx(2)},'date')||contains(src.ColumnName{idx(2)},'time')
                    try
                        tmp=datenum(evt.NewData);
                        tmp_str=datestr(tmp,'yyyy-mm-dd HH:MM:SS.FFF');
                        src.Data{row_id,idx(2)}=tmp_str(1:end-2);
%                         if contains(src.ColumnName{idx(2)},'date')
%                             src.Data{row_id,idx(2)}=datestr(tmp,'yyyy-mm-dd HH:MM:SS');
%                         else
%                             src.Data{row_id,idx(2)}=datestr(tmp,'yyyy-mm-dd HH:MM:SS');
%                         end
                    catch
                        src.Data{row_id,idx(2)}=evt.PreviousData;
                    end
                elseif contains(src.ColumnName{idx(2)},'ship_name')
                    fmt=handles.deployment_table.ColumnFormat(contains(handles.deployment_table.ColumnName,'deployment_ship'));
                    if any(strcmp(fmt{:},evt.NewData))
                        src.Data{row_id,idx(2)}=evt.PreviousData;
                    else
                        handles.deployment_table.ColumnFormat(contains(handles.deployment_table.ColumnName,'deployment_ship'))={unique(src.Data(:,idx(2)))'};
                    end
                end
                if isnumeric(src.Data{row_id,idx(2)})
                    src.Data{row_id,idx(2)}=strtrim(num2str(src.Data{row_id,idx(2)}));
                else
                    src.Data{row_id,idx(2)}=strtrim(src.Data{row_id,idx(2)});
                end
            case 'numeric'
                if isnan(evt.NewData)
                    src.Data{row_id,idx(2)}=evt.PreviousData;
                end
                
        end
    end
    data_ins=src.Data{row_id,idx(2)};
    if idx(2)~=1
        switch src.Tag
            case 't_deployment'
                pkey_name='deployment_pkey';
            case 't_mission'
                pkey_name='mission_pkey';
            case 't_ship'
                pkey_name='ship_pkey';
        end
        try
            dbconn=connect_to_db(handles.db_file);
            switch colname
                case 'deployment_ship'
                    data_ins_name='deployment_ship_key';
                    data_ins=dbconn.fetch(sprintf('SELECT ship_pkey FROM t_ship  WHERE ship_name=''%s''',src.Data{row_id,contains(colnames,'deployment_ship')}));
                    
                case 'deployment_type'
                    data_ins_name='deployment_type_key';
                    data_ins=dbconn.fetch(sprintf('SELECT deployment_type_pkey FROM t_deployment_type  WHERE deployment_type=''%s''',src.Data{row_id,contains(colnames,'deployment_type')}));
                    
                case 'ship_type'
                    data_ins_name='ship_type_key';
                    data_ins=dbconn.fetch(sprintf('SELECT ship_type_pkey FROM t_ship_type  WHERE ship_type=''%s''',src.Data{row_id,contains(colnames,'ship_type')}));
                    
                case 'edit'
                    return;
                otherwise
                    data_ins_name=colname;
            end
            if istable(data_ins)
                data_ins=data_ins{1,1};
            end
            
            if iscell(data_ins)
                data_ins=data_ins{1};
            end
            if isnumeric(data_ins)
                fmt='%d';
            else
                fmt='''%s''';
            end
            sql_cmd=sprintf(['UPDATE %s SET %s' '=' fmt ' WHERE %s=%d'],src.Tag,data_ins_name,data_ins,pkey_name,pkey);
            dbconn.exec(sql_cmd);
            dbconn.close();
            
            update_str(db_fig,'deployment');
            update_str(db_fig,'mission');
        catch
            src.Data{idx(1),idx(2)}=evt.PreviousData;
        end
    end
else
    src.Data{idx(1),idx(2)}=evt.PreviousData;
end
end
% function set_multi_select(h_m_table,m)
%
% j_scrollpane = findjobj(h_m_table);
%
% j_table = j_scrollpane.getViewport.getView;
% j_table.setNonContiguousCellSelection(false);
% j_table.setColumnSelectionAllowed(false);
% j_table.setRowSelectionAllowed(true);
%
% j_table.setSelectionMode(m);
%
% end