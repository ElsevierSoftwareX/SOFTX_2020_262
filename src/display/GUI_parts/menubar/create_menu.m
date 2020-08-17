%% create_menu.m
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
% * 2015-06-25: first version (Yoann Ladroit)
%
% *EXAMPLE
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function create_menu(main_figure)

if isappdata(main_figure,'main_menu')
    menu=getappdata(main_figure,'main_menu');
    menu_f=fieldnames(menu);
    for ifif=1:numel(menu_f)
        if isvalid(menu.(menu_f{ifif}))
            delete(menu.(menu_f{ifif}));
        end
    end
    rmappdata(main_figure,'main_menu');
end

curr_disp=get_esp3_prop('curr_disp');

main_menu.files = uimenu(main_figure,'Label','File(s)');
uimenu(main_menu.files,'Label','Open file','Callback',{@open_file_cback,0});
uimenu(main_menu.files,'Label','Open next file','Callback',{@open_file_cback,1});
uimenu(main_menu.files,'Label','Open previous file','Callback',{@open_file_cback,2});
%uimenu(main_menu.files,'Label','Reload Current file(s)','Callback',{@reload_file,main_figure});
uimenu(main_menu.files,'Label','Index Files','Callback',{@index_files_callback,main_figure});
uimenu(main_menu.files,'Label','Clean temp. files','Callback',{@clean_temp_files_callback,main_figure});
uimenu(main_menu.files,'Label','Open log file','Callback',{@open_logfile_cback,main_figure},'separator','on');

main_menu.bottom_menu = uimenu(main_figure,'Label','Bottom/Regions');
if ~isdeployed
    mcvs = uimenu(main_menu.bottom_menu,'Label','CVS','Tag','menucvs');
    uimenu(mcvs,'Label','Load Bottom and Regions (if linked to dfile...)','Callback',{@load_bot_reg_callback,main_figure});
    uimenu(mcvs,'Label','Load Bottom (if linked to dfile...)','Callback',{@load_bot_callback,main_figure});
    uimenu(mcvs,'Label','Load Regions (if linked to dfile...)','Callback',{@load_reg_callback,main_figure});
    uimenu(mcvs,'Label','Reload opened Layers CVS Bottom/Regions','Callback',{@reload_cvs_callback,main_figure});
    uimenu(mcvs,'Label','Remove opened Layers CVS Bottom/Regions','Callback',{@remove_cvs_callback,main_figure});
end

main_menu.bottom_menu_xml = uimenu(main_menu.bottom_menu,'Label','XML','Tag','menucvs');
uimenu(main_menu.bottom_menu_xml,'Label','Save Bottom/Regions to xml','Callback',{@save_bot_reg_xml_to_db_callback,main_figure,0,0});
uimenu(main_menu.bottom_menu_xml,'Label','Save Bottom to xml','Callback',{@save_bot_reg_xml_to_db_callback,main_figure,0,[]});
uimenu(main_menu.bottom_menu_xml,'Label','Save Regions to xml','Callback',{@save_bot_reg_xml_to_db_callback,main_figure,[],0});
uimenu(main_menu.bottom_menu_xml,'Label','Load Bottom/Regions from xml','Callback',{@import_bot_regs_from_xml_callback,main_figure,-1,-1},'separator','on');
uimenu(main_menu.bottom_menu_xml,'Label','Load Bottom from xml','Callback',{@import_bot_regs_from_xml_callback,main_figure,-1,[]});
uimenu(main_menu.bottom_menu_xml,'Label','Load Regions from xml','Callback',{@import_bot_regs_from_xml_callback,main_figure,[],-1});

main_menu.bottom_menu_db = uimenu(main_menu.bottom_menu,'Label','DB','Tag','menucvs');
uimenu(main_menu.bottom_menu_db,'Label','Save Bottom/Regions to db','Callback',{@save_bot_reg_xml_to_db_callback,main_figure,1,1});
uimenu(main_menu.bottom_menu_db,'Label','Save Bottom to db','Callback',{@save_bot_reg_xml_to_db_callback,main_figure,1,[]});
uimenu(main_menu.bottom_menu_db,'Label','Save Regions to db','Callback',{@save_bot_reg_xml_to_db_callback,main_figure,[],1});
uimenu(main_menu.bottom_menu_db,'Label','Load Bottom and/or Regions from db','Callback',{@manage_version_calllback,main_figure},'separator','on');


%% Export tab
main_menu.export = uimenu(main_figure,'Label','Export','Tag','menuexport');

uimenu(main_menu.export,'Label','Save Echogram','Callback',@save_echo_callback);

exp_values_menu = uimenu(main_menu.export,'Label','Export Echogram Data to .xlsx');
uimenu(exp_values_menu,'Label','Sv values ','Callback',{@export_regions_values_callback,main_figure,'wc','sv'});
uimenu(exp_values_menu,'Label','Currently displayed data values','Callback',{@export_regions_values_callback,main_figure,'wc','curr_data'});

att_exp_menu = uimenu(main_menu.export,'Label','Attitude','Tag','menuexportatt');
uimenu(att_exp_menu,'Label','Export to _att_data.csv file','Callback',{@export_attitude_to_csv_callback,main_figure,[],'_att_data'});

bot_exp_menu = uimenu(main_menu.export,'Label','Bottom (depth, E1/E2)','Tag','menuexportbot');
uimenu(bot_exp_menu,'Label','Export to shapefile','Callback',{@export_bottom_to_shapefile_callback,main_figure,[]});

gps_exp_menu = uimenu(main_menu.export,'Label','Position (GPS)','Tag','menuexportgps');
uimenu(gps_exp_menu,'Label','Export to _gps_data.csv file','Callback',{@export_gps_to_csv_callback,main_figure,[],'_gps_data'});
uimenu(gps_exp_menu,'Label','Export to shapefile','Callback',{@export_gps_to_shapefile_callback,main_figure,[]});
uimenu(gps_exp_menu,'Label','Export to .csv or shapefile from raw files','Callback',{@export_nav_to_csv_from_raw_dlbox,main_figure});
uimenu(gps_exp_menu,'Label','Force update of GPS data in database','Callback',@force_ping_db_update_cback);

NMEA_exp_menu = uimenu(main_menu.export,'Label','NMEA messages','Tag','menuexportnmea');
uimenu(NMEA_exp_menu,'Label','Export to _NMEA.csv file','Callback',{@export_NMEA_to_csv_callback,main_figure,[],'_NMEA'});

st_exp_menu = uimenu(main_menu.export,'Label','Single Targets/Tracks','Tag','menuexportst');
uimenu(st_exp_menu,'Label','Export Single Targets to .xlsx file','Callback',{@save_st_to_xls_callback,main_figure,0});
uimenu(st_exp_menu,'Label','Export Single Targets including signal to .xlsx file','Callback',{@save_st_to_xls_callback,main_figure,1});
uimenu(st_exp_menu,'Label','Export Tracked Targets to .xlsx file','Callback',{@save_tt_to_xls_callback,main_figure});


%% Import tab
main_menu.import = uimenu(main_figure,'Label','Import','Tag','menuimport');

ext_imp_menu= uimenu(main_menu.import,'Label','Attitude and position','Tag','menuimportatt');
uimenu(ext_imp_menu,'Label','Import GPS from .mat or .csv','Callback',{@import_gps_from_csv_callback,main_figure});
uimenu(ext_imp_menu,'Label','Import Attitude from .csv or 3DM*.log file','Callback',{@import_att_from_csv_callback,main_figure});

bot_reg_imp_menu= uimenu(main_menu.import,'Label','Bottom/Region','Tag','menuimportbotreg');
uimenu(bot_reg_imp_menu,'Label','Import Bottom from .evl','Callback',{@import_bot_from_evl_callback,main_figure});
uimenu(bot_reg_imp_menu,'Label','Import Regions from .evr','Callback',{@import_regs_from_evr_callback,main_figure});
uimenu(bot_reg_imp_menu,'Label','Import Regions from LSSS .snap','Callback',{@import_from_lsss_snap_callback,main_figure});


%% Survey data tab
main_menu.survey = uimenu(main_figure,'Label','Survey Data','Tag','menu_survey');
uimenu(main_menu.survey,'Label','Reload Survey Data','Callback',{@import_survey_data_callback,main_figure});
uimenu(main_menu.survey,'Label','Edit Voyage Informations','Callback',{@edit_trip_info_callback,main_figure});
if ~isdeployed()
    uimenu(main_menu.survey,'Label','Set Time Zone for this trip','Callback',{@edit_timezone_callback,main_figure});
end

uimenu(main_menu.survey,'Label','Edit/Display logbook','Callback',{@logbook_dispedit_callback,main_figure});
uimenu(main_menu.survey,'Label','Look for new files in current folder','Callback',{@look_for_new_files_callback,main_figure})
uimenu(main_menu.survey,'Label','Acoustic DB tool','Callback',{@acoustic_db_tool_cback,main_figure});

main_menu.map=uimenu(main_figure,'Label','Mapping Tools','Tag','mapping');
uimenu(main_menu.map,'Label','Open/Undock Map','Callback',{@display_map_callback,main_figure});
uimenu(main_menu.map,'Label','Display navigation from raw files','Callback',{@plot_gps_track_from_files_callback,main_figure});
uimenu(main_menu.map,'Label','Map from current layers (integrated)','Callback',{@load_map_fig_callback,main_figure},'separator','on');
uimenu(main_menu.map,'Label','Map survey result files','Callback',{@map_survey_callback,main_figure});

main_menu.display = uimenu(main_figure,'Label','Display','Tag','menutags');

m_gpu=uimenu(main_menu.display,'Label','GPU Computation');
main_menu.gpu_enabled=uimenu(m_gpu,'Label','Enabled','Callback',{@change_gpu_comp_callback,main_figure},'checked',curr_disp.GPU_computation>0,'tag','enabled');
main_menu.gpu_disabled=uimenu(m_gpu,'Label','Disabled','Callback',{@change_gpu_comp_callback,main_figure},'checked',curr_disp.GPU_computation==0,'tag','disabled');


m_graphics=uimenu(main_menu.display,'Label','Graphics Quality');
main_menu.disp_high_quality=uimenu(m_graphics,'Label','High (slower)','Callback',{@change_echoquality_callback,main_figure},'checked',strcmpi(curr_disp.EchoQuality,'high'),'tag','high');
main_menu.disp_medium_quality=uimenu(m_graphics,'Label','Medium','Callback',{@change_echoquality_callback,main_figure},'checked',strcmpi(curr_disp.EchoQuality,'medium'),'tag','medium');
main_menu.disp_low_quality=uimenu(m_graphics,'Label','Low','Callback',{@change_echoquality_callback,main_figure},'checked',strcmpi(curr_disp.EchoQuality,'low'),'tag','low');
main_menu.disp_very_low_quality=uimenu(m_graphics,'Label','Very Low','Callback',{@change_echoquality_callback,main_figure},'checked',strcmpi(curr_disp.EchoQuality,'very_low'),'tag','very_low');

m_font=uimenu(main_menu.display,'Label','Font');
uimenu(m_font,'Label','Change Font','Callback',{@change_font_callback,main_figure});


m_colormap=uimenu(main_menu.display,'Label','Colormap');

cmap_list=list_cmaps();

for imap=1:numel(cmap_list)
    uimenu(m_colormap,'Label',cmap_list{imap},'Callback',{@change_cmap_callback,main_figure},'Tag',cmap_list{imap});
end
uimenu(m_colormap,'Label','Add new Cmap(s) from cpt file','Callback',{@import_new_cmap_callback,main_figure},'separator','on');


main_menu.disp_colorbar=uimenu(main_menu.display,'Label','Show Colorbar','checked',curr_disp.DispColorbar,'Tag','DispColorbar');
main_menu.disp_bottom=uimenu(main_menu.display,'checked',curr_disp.DispBottom,'Label','Display bottom','Tag','DispBottom');
main_menu.disp_spikes=uimenu(main_menu.display,'checked',curr_disp.DispSpikes,'Label','Display Spikes','Tag','DispSpikes');
main_menu.disp_bad_trans=uimenu(main_menu.display,'checked',curr_disp.DispBadTrans,'Label','Display Bad Pings','Tag','DispBadTrans');
main_menu.disp_reg=uimenu(main_menu.display,'checked',curr_disp.DispReg,'Label','Display Regions','Tag','DispReg');
main_menu.disp_tracks=uimenu(main_menu.display,'checked',curr_disp.DispTracks,'Label','Display_tracks','Tag','DispTracks');
main_menu.disp_lines=uimenu(main_menu.display,'checked',curr_disp.DispLines,'Label','Display Lines','Tag','DispLines');
main_menu.disp_survey_lines=uimenu(main_menu.display,'checked',curr_disp.DispSurveyLines,'Label','Display Survey Lines','Tag','DispSurveyLines');
main_menu.disp_under_bot=uimenu(main_menu.display,'checked',curr_disp.DispUnderBottom,'Label','Display Under Bottom data','Tag','DispUnderBottom');

main_menu.display_file_lines=uimenu(main_menu.display,'checked','off','Label','Display File Limits','Callback',{@checkbox_callback,main_figure,@toggle_display_file_lines});
main_menu.ydir=uimenu(main_menu.display,'checked','off','Label','Reverse Y-Axis','Tag','YDir');


set([main_menu.disp_colorbar...
    main_menu.disp_tracks...
    main_menu.disp_under_bot...
    main_menu.disp_bottom....
    main_menu.disp_bad_trans...
    main_menu.disp_lines....
    main_menu.disp_reg....
    main_menu.disp_spikes....
    main_menu.disp_survey_lines],....
    'callback',@set_curr_disp);


main_menu.close_all_fig=uimenu(main_menu.display,'Label','Close All External Figures','Callback',{@close_figures_callback,main_figure});

main_menu.tools = uimenu(main_figure,'Label','Tools','Tag','menutools');

reg_tools=uimenu(main_menu.tools,'Label','Regions tools');
uimenu(reg_tools,'Label','Create WC Region','Callback',{@create_reg_dlbox,main_figure});
uimenu(reg_tools,'Label','Display Mean Depth of current region','Callback',{@plot_mean_aggregation_depth_callback,main_figure});

% if ~isdeployed
%     uimenu(reg_tools,'Label','Slice Transect','CallBack',{@save_sliced_transect_to_xls_callback,main_figure,0});
% end

towbody_tools=uimenu(main_menu.tools,'Label','Towbody tools');
uimenu(towbody_tools,'Label','Correct position based on cable angle and towbody depth','Callback',{@correct_pos_angle_depth_cback,main_figure});

if ~isdeployed
    bs_tools=uimenu(main_menu.tools,'Label','Backscatter Analysis');
    uimenu(bs_tools,'Label','Execute BS analysis','Callback',{@bs_analysis_callback,main_figure});
end

env_tools=uimenu(main_menu.tools,'Label','Environment tools');
uimenu(env_tools,'Label','Load CTD (ESP3 format)','Callback',{@load_ctd_esp3_callback,main_figure});
uimenu(env_tools,'Label','Load SVP (ESP3 Format)','Callback',{@load_svp_esp3_callback,main_figure});
uimenu(env_tools,'Label','Compute SVP from CTD profile','Callback',{@compute_svp_esp3_callback,main_figure});
env_tools_imp=uimenu(env_tools,'Label','External imports');
uimenu(env_tools_imp,'Label','Load CTD data from Seabird file','Callback',{@load_ctd_callback,main_figure});
uimenu(env_tools_imp,'Label','Load SVP data from file','Callback',{@load_svp_callback,main_figure});

data_tools=uimenu(main_menu.tools,'Label','Data tools');
if ~isdeployed
    uimenu(data_tools,'Label','Import angles from other frequency','Callback',{@import_angles_cback,main_figure});
end

uimenu(data_tools,'Label','Create Motion Compensation echogram','Callback',{@create_motion_compensation_echogramm_cback,main_figure});
uimenu(data_tools,'Label','Convert Sv to fish Density','Callback',{@create_fish_density_echogramm_cback,main_figure});
rm_tools=uimenu(data_tools,'Label','Remove Data');
uimenu(rm_tools,'Label','Denoised data','Callback',{@rm_subdata_cback,main_figure,'denoised'});
uimenu(rm_tools,'Label','Single Targets','Callback',{@rm_subdata_cback,main_figure,'st'});


track_tools=uimenu(main_menu.tools,'Label','Track');
uimenu(track_tools,'Label','Create Exclude Regions from Tracked targets','Callback',{@create_regs_from_tracks_callback,'Bad Data',main_figure,{}});
uimenu(track_tools,'Label','Create Regions from Tracked targets','Callback',{@create_regs_from_tracks_callback,'Data',main_figure,{}});

survey_results_tools=uimenu(main_menu.tools,'Label','Survey results Tools');
uimenu(survey_results_tools,'Label','Display survey results','Callback',{@display_survey_results_cback,main_figure});

main_menu.scripts = uimenu(main_figure,'Label','Scripting');
uimenu(main_menu.scripts ,'Label','Script Manager','Callback',{@load_xml_scripts_callback,main_figure});
uimenu(main_menu.scripts ,'Label','Script Builder','Callback',{@load_script_builder_callback,main_figure});
if ~isdeployed
    uimenu(main_menu.scripts ,'Label','MBS Scripts','Callback',{@load_mbs_scripts_callback,main_figure},'separator','on');
end

main_menu.options = uimenu(main_figure,'Label','Config','Tag','main_menu.options');
uimenu(main_menu.options,'Label','Path','Callback',{@load_path_fig,main_figure});
uimenu(main_menu.options,'Label','Save Current Display Configuration (Survey)','Callback',{@save_disp_config_survey_cback,main_figure});
uimenu(main_menu.options,'Label','Save Current Display Configuration (Default)','Callback',{@save_disp_config_cback,main_figure});


main_menu.help_shortcuts=uimenu(main_figure,'Label','Help');
uimenu(main_menu.help_shortcuts,'Label','Shortcuts','Callback',{@shortcut_menu,main_figure});
uimenu(main_menu.help_shortcuts,'Label','Documentation','Callback',{@load_doc_fig_cback,main_figure});
uimenu(main_menu.help_shortcuts,'Label','About','Callback',{@info_menu,main_figure});

setappdata(main_figure,'main_menu',main_menu);

end

function force_ping_db_update_cback(~,~)
layer_obj = get_current_layer();
layer_obj.add_ping_data_to_db([],1);
update_map_tab
end

function open_file_cback(~,~,id)
esp3_obj = getappdata(groot,'esp3_obj');

if ~isempty(esp3_obj)
    esp3_obj.open_file(id);
end

end

function display_survey_results_cback(src,evt,main_figure)
app_path=get_esp3_prop('app_path');

[Filenames,PathToFile]=uigetfile({fullfile(app_path.results.Path_to_folder,'*_output.txt;*_output.mat')}, 'Pick a survey_ouptput file','MultiSelect','on');

if ~isequal(Filenames, 0)
    
    if ~iscell(Filenames)
        Filenames={Filenames};
    end
    
    Filenames_tot=fullfile(PathToFile,Filenames);
    
    obj_vec=load_surv_obj_frome_result_files(Filenames_tot);
    
    if ~isempty(obj_vec)
        hfig=new_echo_figure(main_figure,'Name','Survey Results','Tag','Survey Results');
        obj_vec.plot_survey_strat_result(hfig);
        for ii=1:length(obj_vec)
            hfig_2=new_echo_figure(main_figure,'Name',sprintf('Survey Results %s: Transect',Filenames{ii}),'Tag',sprintf('results_trans%s',Filenames{ii}));
            obj_vec(ii).plot_survey_trans_result(hfig_2);
        end
    end
    
    
else
    return;
end
end
function load_doc_fig_cback(~,~,main_figure)
load_documentation_figure(main_figure);
end

function load_script_builder_callback(~,~,main_figure)

layer=get_current_layer();

if isempty(layer)
    path_f=pwd;
else
    [path_f,~,~]=fileparts(layer.Filename{1});
end
create_xml_script_gui('main_figure',main_figure,'logbook_file',path_f);

end

function change_echoquality_callback(src,~,main_figure)
curr_disp=get_esp3_prop('curr_disp');

if ~strcmpi(curr_disp.EchoQuality,src.Tag)
    curr_disp.EchoQuality=src.Tag;
end
end

function  change_gpu_comp_callback(src,~,main_figure)
curr_disp=get_esp3_prop('curr_disp');
main_menu=getappdata(main_figure,'main_menu');

switch src.Tag
    case 'enabled'
        set(main_menu.gpu_enabled,'checked',~strcmpi(main_menu.gpu_enabled.Checked,'on'));
        set(main_menu.gpu_disabled,'checked',strcmpi(main_menu.gpu_enabled.Checked,'off'));
    case 'disabled'
        set(main_menu.gpu_disabled,'checked',~strcmpi(main_menu.gpu_disabled.Checked,'on'));
        set(main_menu.gpu_enabled,'checked',strcmpi(main_menu.gpu_disabled.Checked,'off'));
end

curr_disp.GPU_computation=strcmpi(main_menu.gpu_enabled.Checked,'on');

if curr_disp.GPU_computation>0
    disp_perso(main_figure,'GPU Computation enabled');
else
    disp_perso(main_figure,'GPU Computation disabled');
end

end


function display_map_callback(~,~,main_figure)

undock_tab_callback([],[],main_figure,'map','new_fig');
end
function acoustic_db_tool_cback(~,~,main_figure)
enter_new_trip_in_database(main_figure,[]);
end


function save_disp_config_cback(~,~,main_figure)
curr_disp=get_esp3_prop('curr_disp');

write_config_display_to_xml(curr_disp);

end


function save_disp_config_survey_cback(~,~,main_figure)
curr_disp=get_esp3_prop('curr_disp');
layer=get_current_layer();

if isempty(layer)
    return;
end

filepath=fileparts(layer.Filename{1});
write_config_display_to_xml(curr_disp,'file_path',filepath,'limited',1);

end

function edit_timezone_callback(~,~,main_figure)

layer=get_current_layer();
if isempty(layer)
    return;
end
[path_to_db,~,~]=fileparts(layer.Filename{1});
if isfolder(path_to_db)
    set_folder_time_zone(main_figure,path_to_db);
end

end

function correct_pos_angle_depth_cback(src,~,main_figure)

layer=get_current_layer();

if isempty(layer)
    return;
end

prompt={'Towing cable angle (in degree)','Towbody depth'};
defaultanswer={25,500};


[answer,cancel]=input_dlg_perso(main_figure,'Correct position',prompt,...
    {'%.0f' '%.1f'},defaultanswer);
if cancel
    return;
end

angle_deg=answer{1};

if isnan(angle_deg)
    warning('Invalid Angle');
    return;
end

depth_m=answer{2};

if isnan(depth_m)
    warning('Invalid Depth');
    return;
end

curr_disp=get_esp3_prop('curr_disp');
[trans_obj,idx_freq]=layer.get_trans(curr_disp);


gps_data=trans_obj.GPSDataPing;

[new_lat,new_long,hfig]=correct_pos_angle_depth(gps_data.Lat,gps_data.Long,angle_deg,depth_m);


war_str='Would you like to use this corrected track (in red)?';

choice=question_dialog_fig(main_figure,'',war_str);

close(hfig);

switch choice
    case 'Yes'
        trans_obj.GPSDataPing.Lat=new_lat;
        trans_obj.GPSDataPing.Long=new_long;
        layer.replace_gps_data_layer(trans_obj.GPSDataPing);
        export_gps_to_csv_callback([],[],main_figure,layer.Unique_ID,'_gps');
    case 'No'
        return;
        
end


update_map_tab(main_figure);


set_alpha_map(main_figure);

end


function manage_version_calllback(~,~,main_figure)

load_bot_reg_data_fig_from_db(main_figure);


end


function clean_temp_files_callback(src,~,main_figure)
layers=get_esp3_prop('layers');

temp_files_in_use=layers.list_memaps();
app_path=get_esp3_prop('app_path');

files_in_temp=dir(app_path.data_temp.Path_to_folder);

idx_delete=[];
for uu=1:length(files_in_temp)
    if nansum(strcmpi(fullfile(app_path.data_temp.Path_to_folder,files_in_temp(uu).name),temp_files_in_use))==0&&files_in_temp(uu).isdir==0
        idx_delete=[idx_delete uu];
    end
end

for i=1:length(idx_delete)
    if isfile(fullfile(app_path.data_temp.Path_to_folder,files_in_temp(idx_delete(i)).name))
        delete(fullfile(app_path.data_temp.Path_to_folder,files_in_temp(idx_delete(i)).name));
    end
end

fprintf('%d files deleted, %.0f Mb\n',length(idx_delete),nansum([files_in_temp(idx_delete).bytes])/1e6);

end

function change_cmap_callback(src,~,main_fig)
curr_disp=get_esp3_prop('curr_disp');
curr_disp.Cmap=src.Tag;
set_esp3_prop('curr_disp',curr_disp);
end

function change_font_callback(~,~,main_fig)
curr_disp=get_esp3_prop('curr_disp');
fonts=listfonts(main_fig);
i_font=find(strcmp(curr_disp.Font,fonts));

if isempty(i_font)
    i_font=1;
end

list_font_figure= new_echo_figure(main_fig,'Units','Pixels','Position',[100 100 200 600],'Resize','off',...
    'Name','Choose Font',...
    'Tag','font_choice');

uicontrol(list_font_figure,'Style','listbox','min',0,'max',0,'value',i_font,'string',fonts,'units','normalized','position',[0.1 0.05 0.8 0.9],'callback',{@list_font_cback,main_fig})

end

function list_font_cback(src,~,main_fig)
curr_disp=get_esp3_prop('curr_disp');
fonts = get(src,'String');
s = get(src,'Value');
curr_disp.Font=fonts{s};
set_esp3_prop('curr_disp',curr_disp);
end



function load_map_fig_callback(~,~,main_fig)
load_map_fig(main_fig,[]);
end


function look_for_new_files_callback(~,~,main_figure)
layer=get_current_layer();
if isempty(layer)
    return;
end
layer.update_echo_logbook_dbfile('main_figure',main_figure);
load_logbook_tab_from_db(main_figure,0);

end

function open_logfile_cback(~,~,main_figure)
open_txt_file(main_figure.UserData.logFile);
end


function set_curr_disp(src,~)

curr_disp=get_esp3_prop('curr_disp');
switch src.Tag
    case 'YDir'
        switch  src.Checked
            case 'off'
                curr_disp.(src.Tag)='reverse';
                src.Checked  = 'on';
            case 'on'
                curr_disp.(src.Tag)='normal';
                src.Checked  = 'off';
        end
    otherwise
        
        switch src.Checked
            case {'off',0,false}
                curr_disp.(src.Tag)='on';
                src.Checked  = 'on';
            case {'on',1,true}
                curr_disp.(src.Tag)='off';
                src.Checked  = 'off';
        end
end
end



