%% update_display.m
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
% * |new|: TODO: write description and info on variable
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
function update_display(main_figure,new,force_update)

if ~isdeployed
    disp_perso(main_figure,'Update Display');
end

if ~isappdata(main_figure,'Axes_panel')
    
    echo_tab_panel=getappdata(main_figure,'echo_tab_panel');
    axes_panel=uitab(echo_tab_panel,'BackgroundColor',[1 1 1],'tag','axes_panel');
    
%     cur_ver = ver('Matlab');
%     axes_panel=new_echo_figure(main_figure,'tag','axes_panel','Units','Normalized','Position',[0.1 0.1 0.8 0.8],'UiFigureBool',str2double(cur_ver.Version)>9.7);
%     axes_panel.Alphamap = main_figure.Alphamap;  
%     initialize_interactions_v2(axes_panel);
%     
    load_axis_panel(main_figure,axes_panel);
    display_tab_comp=getappdata(main_figure,'Display_tab');
    load_mini_axes(main_figure,display_tab_comp.display_tab,[0 0 1 0.67]);
    enabled_obj=findobj(main_figure,'Enable','off');
    set(enabled_obj,'Enable','on');
end


opt_panel=getappdata(main_figure,'option_tab_panel');
sel_tab=opt_panel.SelectedTab;

layer=get_current_layer();

if isempty(layer)
    return;
end

disp_perso(main_figure,'Updating Display');

if new==1
    update_algo_panels(main_figure,{});    
    update_denoise_tab(main_figure);   
    update_processing_tab(main_figure);
    update_map_tab(main_figure);
    update_st_tracks_tab(main_figure);
    update_multi_freq_disp_tab(main_figure,'sv_f',0);
    update_multi_freq_disp_tab(main_figure,'ts_f',0);
    update_lines_tab(main_figure);
    update_calibration_tab(main_figure);
    update_environnement_tab(main_figure,1);
    update_tree_layer_tab(main_figure);
    update_reglist_tab(main_figure,1);
    clear_regions(main_figure,{},{});
    update_multi_freq_tab(main_figure);
    clean_echo_figures(main_figure,'Tag','attitude');
end

update_axis(main_figure,new,'main_or_mini','main','force_update',force_update);

if new==1
    update_display_tab(main_figure);
    load_secondary_freq_win(main_figure,0);
    update_file_panel(main_figure);
end

update_echo_int_tab(main_figure,new);

try
    update_axis(main_figure,new,'main_or_mini','mini','force_update',force_update);
catch
    display_tab_comp=getappdata(main_figure,'Display_tab');
    load_mini_axes(main_figure,display_tab_comp.display_tab,[0 0 1 0.67]);
    update_axis(main_figure,new,'main_or_mini','mini','force_update',force_update);
end
curr_disp=get_esp3_prop('curr_disp');
if new==1
    init_sec_link_props(main_figure);
end
upped=update_axis(main_figure,new,'main_or_mini',curr_disp.SecChannelIDs,'force_update',force_update);

set_alpha_map(main_figure,'main_or_mini',union({'main','mini'},curr_disp.SecChannelIDs(upped>0),'stable'));
if ~isempty(sel_tab)
    opt_panel.SelectedTab=sel_tab;
end
set_axes_position(main_figure);
update_cmap(main_figure);
init_link_prop(main_figure);

if new==1
    secondary_freq=getappdata(main_figure,'Secondary_freq');
    if ~isempty(secondary_freq)
        if ~isempty(secondary_freq.axes)
            if strcmpi(secondary_freq.axes(1).UserData.geometry_y,'depth')
                ylim=get(secondary_freq.axes(1),'Ylim');
                set(secondary_freq.axes,'ytick',floor((ylim(1):curr_disp.Grid_y:ylim(2))/curr_disp.Grid_y)*curr_disp.Grid_y);
                set(secondary_freq.side_ax,'ytick',floor((ylim(1):curr_disp.Grid_y:ylim(2))/curr_disp.Grid_y)*curr_disp.Grid_y);
            end
        end
    end
end

display_bottom(main_figure);
display_tracks(main_figure);
display_file_lines(main_figure);
display_lines(main_figure);
display_regions(main_figure);
display_survdata_lines(main_figure);

order_axes(main_figure);

update_info_panel([],[],1);

curr_disp=get_esp3_prop('curr_disp');
disp_perso(main_figure,'');

curr_disp.UIupdate=0;



end