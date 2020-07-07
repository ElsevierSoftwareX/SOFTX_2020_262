%% load_axis_panel.m
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
% * |axes_panel|: TODO: write description and info on variable
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
function load_axis_panel(main_figure,axes_panel)

if ~isempty(main_figure)&&isappdata(main_figure,'Axes_panel')
    axes_panel_comp=getappdata(main_figure,'Axes_panel');
    delete(axes_panel_comp.axes_panel);
    rmappdata(main_figure,'Axes_panel');
    axes_panel_comp=[];
end

curr_disp=get_esp3_prop('curr_disp');

axes_panel_comp.axes_panel=axes_panel;

axes_panel_comp.echo_obj = echo_disp_cl(axes_panel_comp.axes_panel,'cmap',curr_disp.Cmap);

axes_panel_comp.v_axes_plot=plot(axes_panel_comp.echo_obj.vert_ax,nan,nan,'r');
axes_panel_comp.v_bot_val=yline(axes_panel_comp.echo_obj.vert_ax,0,'-k','Tag','bot_val','Interpreter','none');
axes_panel_comp.v_curr_val=yline(axes_panel_comp.echo_obj.vert_ax,0,'--b','Tag','curr_val','Interpreter','none');       

enterFcnv =  @(figHandle, currentPoint)...
    set(figHandle, 'Pointer', 'right');
iptSetPointerBehavior(axes_panel_comp.echo_obj.vert_ax,enterFcnv);

enterFcnh =  @(figHandle, currentPoint)...
    set(figHandle, 'Pointer', 'top');
iptSetPointerBehavior(axes_panel_comp.echo_obj.hori_ax,enterFcnh);

iptaddcallback(axes_panel_comp.echo_obj.vert_ax,'ButtonDownFcn',{@change_axes_ratio_cback,main_figure,'v'});
iptaddcallback(axes_panel_comp.echo_obj.hori_ax,'ButtonDownFcn',{@change_axes_ratio_cback,main_figure,'h'});

axes_panel_comp.h_axes_plot_low=plot(axes_panel_comp.echo_obj.hori_ax,nan,nan,'color',[0 0.5 0]);
axes_panel_comp.h_axes_plot_high=plot(axes_panel_comp.echo_obj.hori_ax,nan,nan,'color',[0.5 0 0],'linestyle','-','marker','o','MarkerFaceColor',[0.5 0 0]);
axes_panel_comp.h_curr_val=xline(axes_panel_comp.echo_obj.hori_ax,0,'--b','Tag','curr_val','Interpreter','none');       

pt_int.enterFcn =  @(figHandle, currentPoint)...
replace_interaction(figHandle,'interaction','WindowButtonMotionFcn','id',1,'interaction_fcn',{@update_info_panel,0});

pt_int.traverseFcn = [];
pt_int.exitFcn = [];

iptSetPointerBehavior(axes_panel_comp.axes_panel,pt_int);

axes_panel_comp.echo_obj.bottom_line_plot=plot(axes_panel_comp.echo_obj.main_ax,nan,nan,'tag','bottom');

%create_context_menu_bottom(main_figure,axes_panel_comp.echo_obj.bottom_line_plot);

ipt.enterFcn    = @(src, evt) enter_bottom_plot_fcn(src, evt,axes_panel_comp.echo_obj.bottom_line_plot);
ipt.exitFcn     = @(src, evt) exit_bottom_plot_fcn(src, evt,axes_panel_comp.echo_obj.bottom_line_plot);
ipt.traverseFcn = [];
iptSetPointerBehavior(axes_panel_comp.echo_obj.bottom_line_plot,ipt);

axes_panel_comp.listeners=[];

rm_axes_interactions([axes_panel_comp.echo_obj.main_ax axes_panel_comp.echo_obj.vert_ax axes_panel_comp.echo_obj.hori_ax]);

if ~isempty(main_figure)
    setappdata(main_figure,'Axes_panel',axes_panel_comp);
end
end

function exit_bottom_plot_fcn(src,~,hplot)
set(hplot,'linewidth',0.5);
end

function enter_bottom_plot_fcn(src,evt,hplot)
set(src, 'Pointer', 'hand');
set(hplot,'linewidth',2);
end
