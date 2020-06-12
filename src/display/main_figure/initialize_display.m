%% initialize_display.m
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
% * |main_figure|: TODO: write description and info on variable
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
function initialize_display(esp3_obj)

main_figure=esp3_obj.main_figure;
curr_disp=esp3_obj.curr_disp;

pan_height=get_top_panel_height(8.25);
load_loading_bar_panel_v2(main_figure);
load_info_panel(main_figure);

load_bar_comp=getappdata(main_figure,'Loading_bar');
inf_h_tmp=load_bar_comp.panel.Position(4);
info_panel=getappdata(main_figure,'Info_panel');
inf_h=info_panel.info_panel.Position(4);

inf_h=inf_h_tmp+inf_h;

pix_pos=getpixelposition(main_figure);

al_disp_ratio = curr_disp.Al_opt_tab_size_ratio;

opt_panel=uitabgroup(main_figure,'Units','pixels','Position',[0 pix_pos(4)-pan_height (1-al_disp_ratio)*pix_pos(3) pan_height],'tag','opt','ButtonDownFcn',@change_opt_al_tab_ratio);
algo_panel=uitabgroup(main_figure,'Units','pixels','Position',[(1-al_disp_ratio)*pix_pos(3) pix_pos(4)-pan_height al_disp_ratio*pix_pos(3) pan_height],'tag','algo','ButtonDownFcn',@change_opt_al_tab_ratio);

pt_int.enterFcn =  @(figHandle, currentPoint)...
replace_interaction(figHandle,'interaction','WindowButtonMotionFcn','id',1);
pt_int.exitFcn = [];
pt_int.traverseFcn = [];

iptSetPointerBehavior(opt_panel,pt_int);
iptSetPointerBehavior(algo_panel,pt_int);

echo_tab_panel=uitabgroup(main_figure,'Units','pixels','Position',[0 inf_h pix_pos(3) pix_pos(4)-pan_height-inf_h]);

load_info_panel(main_figure);

setappdata(main_figure,'echo_tab_panel',echo_tab_panel);
setappdata(main_figure,'option_tab_panel',opt_panel);
setappdata(main_figure,'algo_tab_panel',algo_panel);

create_menu(main_figure);
load_esp3_panel(main_figure,echo_tab_panel);
load_file_panel(main_figure,echo_tab_panel);
load_echo_int_tab(main_figure,echo_tab_panel)
load_secondary_freq_win(main_figure);

%fixed Tab in option panel
load_cursor_tool(main_figure);
load_display_tab(main_figure,opt_panel);
load_lines_tab(main_figure,opt_panel);
load_calibration_tab(main_figure,opt_panel);
load_environnement_tab(main_figure,opt_panel);
load_processing_tab(main_figure,opt_panel);

%Undockable tabs
load_tree_layer_tab(main_figure,opt_panel);
load_reglist_tab(main_figure,opt_panel);
load_map_tab(main_figure,opt_panel);
load_st_tracks_tab(main_figure,opt_panel);
load_multi_freq_disp_tab(main_figure,opt_panel,'sv_f');
load_multi_freq_disp_tab(main_figure,opt_panel,'ts_f');

load_bottom_tab(main_figure,algo_panel);
load_bad_pings_tab(main_figure,algo_panel);
load_denoise_tab(main_figure,algo_panel);
load_school_detect_tab(main_figure,algo_panel);
load_track_target_tab(main_figure,algo_panel);

load_multi_freq_tab(main_figure,algo_panel);

format_color_gui(main_figure,curr_disp.Font,curr_disp.Cmap);
display_tab_comp=getappdata(main_figure,'Display_tab');
opt_panel.SelectedTab=display_tab_comp.display_tab;
esp3_tab_comp=getappdata(main_figure,'esp3_tab');
echo_tab_panel.SelectedTab=esp3_tab_comp.esp3_tab;
order_option_tab(main_figure);
obj_enable=findobj(main_figure,'Enable','on','-not','Type','uimenu');
set(obj_enable,'Enable','off');
centerfig(main_figure);
set(main_figure,'Visible','on');


end






