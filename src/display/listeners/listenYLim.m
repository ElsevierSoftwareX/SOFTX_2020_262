%% listenYLim.m
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
% * 2017-04-02: header (Alex Schimel).
% * 2016-06-17: first version (Yoann Ladroit). TODO: complete date and comment
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function listenYLim(src,evt,main_figure)
if ~isdeployed
    disp('listenYLim')
    %profile on;
    tic;
end

layer=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');

[trans_obj,~]=layer.get_trans(curr_disp);
ax=evt.AffectedObject;

x_lim=get(ax,'XLim');
y_lim=get(ax,'YLim');


range=trans_obj.get_transceiver_range();
%time=trans_obj.get_transceiver_time();
y_lim=ceil(y_lim);

y_lim(y_lim>numel(range))=numel(range);
y_lim(y_lim<=0)=1;
curr_disp.R_disp=range(y_lim);

% up=update_axis_panel(main_figure,0);
% up_sec=update_secondary_freq_win(main_figure);

cids=union({'main'},curr_disp.SecChannelIDs,'stable');
up=update_axis(main_figure,0,'main_or_mini',cids);

mini_ax_comp=getappdata(main_figure,'Mini_axes');
main_ax=getappdata(main_figure,'Axes_panel');

patch_obj=mini_ax_comp.patch_obj;
new_vert=patch_obj.Vertices;
new_vert(:,1)=[x_lim(1) x_lim(2) x_lim(2) x_lim(1)];
new_vert(:,2)=[y_lim(1) y_lim(1) y_lim(2) y_lim(2)];
set(patch_obj,'Vertices',new_vert);

xd=get(main_ax.echo_obj.echo_surf,'xdata');
yd=get(main_ax.echo_obj.echo_surf,'ydata');

v2 = [nanmin(xd) nanmin(yd);nanmax(xd) nanmin(yd);nanmax(xd) nanmax(yd);nanmin(xd) nanmax(yd)];

set(mini_ax_comp.patch_lim_obj,'Vertices',v2);

if ~any(up)
    drawnow;
    if ~isdeployed
        toc;
    end
    return;
end

set_axes_position(main_figure);

display_bottom(main_figure);
display_tracks(main_figure);
display_file_lines(main_figure);
display_survdata_lines(main_figure);

set_alpha_map(main_figure,'main_or_mini',cids);


update_info_panel([],[],1);
drawnow;

if ~isdeployed
    disp('listenYLim done');
    fprintf('%d graphical objects in ESP3\n',numel(findall(main_figure)));
    toc;
    
    %     profile off;
    %     profile viewer
end




end