%% create_context_menu_bottom.m
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
% * |bottom_line|: TODO: write description and info on variable
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
% * 2017-03-29: header (Alex Schimel).
% * YYYY-MM-DD: first version (Author). TODO: complete date and comment
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function create_context_menu_bottom(main_figure,bottom_line)
curr_disp=get_esp3_prop('curr_disp');
layer=get_current_layer();
[~,idx_freq]=layer.get_trans(curr_disp);

delete(findobj(main_figure,'Type','Uicontextmenu','-and','Tag','botCtxtMenu'));

context_menu=uicontextmenu(ancestor(bottom_line,'figure'),'Tag','botCtxtMenu');
bottom_line.UIContextMenu=context_menu;
switch layer.Filetype
    case 'EK60'
        uimenu(context_menu,'Label','Reload Simrad bottom','Callback',@reload_ek_bot_cback);
end
uimenu(context_menu,'Label','Shift Bottom ...','Callback',{@shift_bottom_callback,[],main_figure});
uimenu(context_menu,'Label','Remove Bottom ...','Callback',{@rm_bottom_callback,main_figure});
uimenu(context_menu,'Label','Display Bottom Region','Callback',@display_bottom_region_callback);
uimenu(context_menu,'Label','Filter Bottom','Callback',@filter_bottom_callback);
% uimenu(context_menu,'Label','Display Slope estimation','Callback',@slope_est_callback);
% uimenu(context_menu,'Label','Display Shadow zone height estimation','Callback',@shadow_zone_est_callback);
uimenu(context_menu,'Label','Display Shadow zone content estimation (10m X 10m)','Callback',@shadow_zone_content_est_callback);

uifreq=uimenu(context_menu,'Label','Copy to other channels');
uimenu(uifreq,'Label','all','Callback',{@copy_bottom_cback,main_figure,[]});
uimenu(uifreq,'Label','choose which channels...','Callback',{@copy_bottom_cback,main_figure,1});

export_menu=uimenu(context_menu,'Label','Export');
uimenu(export_menu,'Label','To Lat/Long/Depth .csv','Callback',{@export_bottom_to_lat_long_depth_csv_cback,main_figure});

end

%%
% subfunctions
%
function rm_bottom_callback(~,~,main_figure)

layer=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');

[trans_obj,~]=layer.get_trans(curr_disp);

old_bot=trans_obj.Bottom;
trans_obj.Bottom=bottom_cl();

curr_disp.Bot_changed_flag=1;


bot=trans_obj.Bottom;
curr_disp.Bot_changed_flag=1;


add_undo_bottom_action(main_figure,trans_obj,old_bot,bot);

set_alpha_map(main_figure,'update_bt',0);
display_bottom(main_figure);


end

function reload_ek_bot_cback(src,evt)
esp3_obj=getappdata(groot,'esp3_obj');
layer=get_current_layer();

curr_disp=get_esp3_prop('curr_disp');

trans_obj=layer.get_trans(curr_disp);
old_bot=trans_obj.Bottom;
layer.load_ek_bot('Channels',{curr_disp.ChannelID})
add_undo_bottom_action(esp3_obj.main_figure,trans_obj,old_bot,trans_obj.Bottom)
display_bottom(esp3_obj.main_figure,'both');
set_alpha_map(esp3_obj.main_figure,'update_bt',0);
update_info_panel([],[],1);
end

function export_bottom_to_lat_long_depth_csv_cback(src,~,main_figure)
curr_disp=get_esp3_prop('curr_disp');
layer=get_current_layer();
[trans_obj,~]=layer.get_trans(curr_disp);
layers_Str=list_layers(layer,'nb_char',80);
[path_lay,~,~]=fileparts(layer.Filename{1});

[filename, pathname] = uiputfile('*.csv',...
    'Save survey csv Metadata file',...
    fullfile(path_lay,[layers_Str{1} '_lat_lon_bot.csv']));

if isequal(filename,0) || isequal(pathname,0)
    return;
end


lat=trans_obj.GPSDataPing.Lat();
lon=trans_obj.GPSDataPing.Long();
d=trans_obj.get_bottom_depth();
t=cellfun(@(x) datestr(x,'dd/mm/yyyy HH:MM:SS'),(num2cell(trans_obj.GPSDataPing.Time())),'UniformOutput',0);

struct_obj.Lat=lat(:);
struct_obj.Lon=lon(:);
struct_obj.Depth=d(:);
struct_obj.Time=t(:);

T = struct2table(struct_obj);

writetable(T,fullfile(pathname,filename));
disp('Bottom saved!');

end



function copy_bottom_cback(src,~,main_figure,ifreq)

layer=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');
[~,idx_freq]=layer.get_trans(curr_disp);

if ~isempty(ifreq)
    idx_other=setdiff(1:numel(layer.Frequencies),idx_freq);
    if isempty(idx_other)
        return;
    end
    
    list_freq_str = cellfun(@(x,y) sprintf('%.0f kHz: %s',x,y),num2cell(layer.Frequencies(idx_other)/1e3), deblank(layer.ChannelID(idx_other)),'un',0);
    
    if isempty(list_freq_str)
        return;
    end
    
    [ifreq,val] = listdlg_perso(main_figure,'',list_freq_str);
    if val==0 || isempty(ifreq)
        return;
    end
    ifreq=layer.find_cid_idx(layer.ChannelID(idx_other(ifreq)));
end

[bots,ifreq]=layer.generate_bottoms_for_other_freqs(idx_freq,ifreq);
for i=1:numel(ifreq)
    old_bot=layer.Transceivers(ifreq(i)).Bottom;
    bots(i).Tag=old_bot.Tag;
    layer.Transceivers(ifreq(i)).Bottom=bots(i);
    add_undo_bottom_action(main_figure,layer.Transceivers(ifreq(i)),old_bot,bots(i));
end

display_bottom(main_figure);
set_alpha_map(main_figure,'main_or_mini',union({'main','mini'},layer.ChannelID(ifreq)),'update_bt',0);

end

function shadow_zone_content_est_callback(src,~)

% prep
main_figure = ancestor(src,'Figure');
axes_panel_comp = getappdata(main_figure,'Axes_panel');

layer = get_current_layer();
curr_disp=get_esp3_prop('curr_disp');
[trans_obj,idx_freq] = layer.get_trans(curr_disp);

time=trans_obj.Time;


ah=axes_panel_comp.haxes;


% estimate shadow zone
[outer_reg,slope_est,shadow_height_est] = trans_obj.estimate_shadow_zone('DispReg',1,'intersect_only',0);

% initalize display
fig_handle = new_echo_figure(main_figure,'Tag','shadow_zone');

% top axes
ax1 = axes(fig_handle,'nextplot','add','units','normalized','OuterPosition',[0 0.5 1 0.5]);
yyaxis(ax1,'left');
plot(ax1,shadow_height_est);
grid(ax1,'on');
xlabel(ax1,'Ping number')
ylabel(ax1,'Shadow Zone (m)');
yyaxis(ax1,'right');
plot(ax1,slope_est);
xlabel(ax1,'Ping number')
ylabel(ax1,'Slope (deg)');

% bottom axes
ax2 = axes(fig_handle,'nextplot','add','units','normalized','OuterPosition',[0 0 1 0.5]);
plot((outer_reg.Ping_E+outer_reg.Ping_S)/2,pow2db_perso(outer_reg.sv_mean),'k')
xlabel(ax2,'Ping number')
ylabel(ax2,'Sv mean(m)')
grid(ax2,'on');

% link axes

fig_handle.UserData=linkprop([ah ax1 ax2],{'XTick' 'XTickLabels' 'XLim'});
end
%
% function slope_est_callback(src,~)
% main_figure=ancestor(src,'Figure');
%
% layer=get_current_layer();
% curr_disp=get_esp3_prop('curr_disp');
% [trans_obj,idx_freq]=layer.get_trans(curr_disp);
%
%
% slope_est=trans_obj.get_slope_est();
%
% fig_handle=new_echo_figure(main_figure,'Tag','slope_est');
% ax=axes(fig_handle);
% plot(ax,slope_est);
% grid(ax,'on');
% xlabel(ax,'Ping number')
% ylabel(ax,'Slope (deg)');
%
% end

function display_bottom_region_callback(src,~)
main_figure=ancestor(src,'Figure');
layer=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');
[trans_obj,~]=layer.get_trans(curr_disp);
load_bar_comp=getappdata(main_figure,'Loading_bar');

% profile on;


reg_wc=trans_obj.create_WC_region('y_min',0,...
    'y_max',25,...
    'Type','Data',...
    'Ref','Bottom',...
    'Cell_w',50,...
    'Cell_h',1,...
    'Cell_w_unit','pings',...
    'Cell_h_unit','meters');

reg_wc.display_region(trans_obj,'main_figure',main_figure,'load_bar_comp',load_bar_comp);

% profile off;
% profile viewer;

end

function filter_bottom_callback(src,~)
main_figure=ancestor(src,'Figure');
prompt={'Filter Width (in pings)'};
defaultanswer={11};

[answer,cancel]=input_dlg_perso(main_figure,'Filter Width',prompt,...
    {'%d'},defaultanswer);
if cancel
    return;
end


if ~isnan(answer{1})
    w_filter=answer{1};
else
    warning('Invalid filter_width');
    return
end
layer=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');
[trans_obj,idx_freq]=layer.get_trans(curr_disp);


trans_obj.filter_bottom('FilterWidth',w_filter);

curr_disp.Bot_changed_flag=1;


display_bottom(main_figure);
set_alpha_map(main_figure,'update_bt',0);

end