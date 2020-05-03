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


if isappdata(main_figure,'Axes_panel')
    axes_panel_comp=getappdata(main_figure,'Axes_panel');
    delete(axes_panel_comp.axes_panel);
    rmappdata(main_figure,'Axes_panel');
    axes_panel_comp=[];
end

axes_panel_comp.axes_panel=axes_panel;

user_data.geometry_y='samples';
user_data.geometry_x='pings';

axes_panel_comp.main_axes=axes('Parent',axes_panel_comp.axes_panel,...
    'FontSize',10,'Units','normalized',...
    'Position',[0 0 1 1],...
    'XAxisLocation','bottom',...
    'XLimMode','manual',...
    'YLimMode','manual',...
    'TickLength',[0 0],...
    'XTickLabel',{[]},...
    'YTickLabel',{[]},...
    'XTickMode','manual',...
    'YTickMode','manual',...
    'box','on',...
    'SortMethod','childorder',...
    'XMinorGrid','on',...
    'YMinorGrid','on',...
    'GridLineStyle','--',...
    'MinorGridLineStyle',':',...
    'NextPlot','add',...
    'YDir','reverse',...
    'visible','on',...
    'ClippingStyle','rectangle',... 
    'Interactions',[],'Toolbar',[],...
    'Tag','main','UserData',user_data);

axes_panel_comp.vaxes=axes('Parent',axes_panel_comp.axes_panel,'FontSize',10,'Fontweight','Bold','Units','normalized',...
    'Interactions',[],'Toolbar',[],...
    'Position',[0 0 0 0],...
    'XAxisLocation','Top',...
    'YAxisLocation','right',...
    'YTickMode','manual',...
    'TickDir','in',...
    'visible','on',...
    'box','on',...
    'XTickLabel',{[]},...
    'Xgrid','on',...
    'Ygrid','on',...
    'NextPlot','add',...
    'ClippingStyle','rectangle',...
    'GridColor',[0 0 0],...
    'YDir','reverse',...
    'visible','on','UserData',user_data);



axes_panel_comp.v_axes_plot=plot(axes_panel_comp.vaxes,nan,nan,'r');
axes_panel_comp.v_bot_val=yline(axes_panel_comp.vaxes,0,'-k','Tag','bot_val','Interpreter','none');
axes_panel_comp.v_curr_val=yline(axes_panel_comp.vaxes,0,'--b','Tag','curr_val','Interpreter','none');       


axes_panel_comp.haxes=axes('Parent',axes_panel_comp.axes_panel,...
    'Interactions',[],'Toolbar',[],...
    'FontSize',10,...
    'Fontweight','Bold',...
    'Units','normalized',...
    'Position',[0 0 0 0],...
    'XAxisLocation','bottom',...
    'YAxisLocation','left',...
    'TickDir','in',...
    'XTickMode','manual',...
    'visible','on',...
    'box','on',...
    'YTickLabel',{[]},...
    'Xgrid','on',...
    'Ygrid','on',...
    'ClippingStyle','rectangle',...
    'NextPlot','add',...
    'GridColor',[0 0 0],...
    'SortMethod','childorder',...
    'visible','on','UserData',user_data);

% linkaxes([axes_panel_comp.main_axes axes_panel_comp.haxes],'x');
% linkaxes([axes_panel_comp.main_axes axes_panel_comp.vaxes],'y');

enterFcnv =  @(figHandle, currentPoint)...
    set(figHandle, 'Pointer', 'right');
iptSetPointerBehavior(axes_panel_comp.vaxes,enterFcnv);

enterFcnh =  @(figHandle, currentPoint)...
    set(figHandle, 'Pointer', 'top');
iptSetPointerBehavior(axes_panel_comp.haxes,enterFcnh);

iptaddcallback(axes_panel_comp.vaxes,'ButtonDownFcn',{@change_axes_ratio_cback,main_figure,'v'});
iptaddcallback(axes_panel_comp.haxes,'ButtonDownFcn',{@change_axes_ratio_cback,main_figure,'h'});


axes_panel_comp.h_axes_plot_low=plot(axes_panel_comp.haxes,nan,nan,'color',[0 0.5 0]);
axes_panel_comp.h_axes_plot_high=plot(axes_panel_comp.haxes,nan,nan,'color',[0.5 0 0],'linestyle','-','marker','o','MarkerFaceColor',[0.5 0 0]);
axes_panel_comp.h_curr_val=xline(axes_panel_comp.haxes,0,'--b','Tag','curr_val','Interpreter','none');       

axes_panel_comp.h_axes_text=text(nan,nan,'','Color','r','VerticalAlignment','bottom','fontsize',10,'parent',axes_panel_comp.haxes,'Clipping', 'on');
axes_panel_comp.colorbar=colorbar(axes_panel_comp.main_axes,'PickableParts','none','visible','off','fontsize',8,'Color',axes_panel_comp.main_axes.Color);
axes_panel_comp.colorbar.UIContextMenu=[];
axes_panel_comp.main_axes.Position=[0 0 1 1];

set(axes_panel_comp.main_axes,'Xgrid','on','Ygrid','on','XAxisLocation','top');
set(axes_panel_comp.vaxes,'box','on');
set(axes_panel_comp.haxes,'XTickLabelRotation',-90,'box','on');

echo_init=zeros(2,2);
curr_disp=get_esp3_prop('curr_disp');
alpha_prop='flat';
%alpha_prop='texturemap';
alpha_prop_bt='flat';

usrdata=init_echo_usrdata();

switch curr_disp.EchoType
    case 'surface'
        axes_panel_comp.main_echo=pcolor(axes_panel_comp.main_axes,echo_init);
        axes_panel_comp.bad_transmits=pcolor(axes_panel_comp.main_axes,zeros(size(echo_init),'uint8'));
        set(axes_panel_comp.main_echo,'Facealpha',alpha_prop,'FaceColor',alpha_prop,'LineStyle','none','tag','echo','AlphaDataMapping','direct','UserData',usrdata); 
        set(axes_panel_comp.bad_transmits,'Facealpha',alpha_prop_bt,'FaceColor',alpha_prop_bt,'LineStyle','none','tag','bad_transmits','AlphaDataMapping','direct');
    case 'image'
        axes_panel_comp.main_echo=image(1:size(echo_init,1),1:size(echo_init,2),uint8(echo_init),'parent',axes_panel_comp.main_axes,'tag','echo','CDataMapping','scaled','AlphaData',0,'AlphaDataMapping','direct','UserData',usrdata);
        axes_panel_comp.bad_transmits=image(1:size(echo_init,1),1:size(echo_init,2),zeros(size(echo_init),'uint8'),'parent',axes_panel_comp.main_axes,'AlphaData',0,'tag','bad_transmits','AlphaDataMapping','direct');
end


pt_int.enterFcn =  @(figHandle, currentPoint)...
replace_interaction(figHandle,'interaction','WindowButtonMotionFcn','id',1,'interaction_fcn',{@update_info_panel,0});
% pt_int.enterFcn=@(figHandle, currentPoint) disp('Entering');
% pt_int.traverseFcn = [];
% % 
% % pt_int.exitFcn =  @(figHandle, currentPoint)...
% %     replace_interaction(figHandle,'interaction','WindowButtonMotionFcn','id',1);
% pt_int.exitFcn=@(figHandle, currentPoint) disp('Exiting');
%                 ipt.exitFcn =  @(figHandle, currentPoint)...
%                     set(figHandle, 'Pointer', 'hand');
pt_int.traverseFcn = [];
pt_int.exitFcn = [];
iptSetPointerBehavior(axes_panel_comp.axes_panel,pt_int);

%set(axes_panel_comp.main_axes,'xlim',[1 size(echo_init,1)],'ylim',[1 size(echo_init,2)]);

axes_panel_comp.bottom_plot=plot(axes_panel_comp.main_axes,nan,nan,'tag','bottom');

create_context_menu_bottom(main_figure,axes_panel_comp.bottom_plot);

ipt.enterFcn    = @(src, evt) enter_bottom_plot_fcn(src, evt,axes_panel_comp.bottom_plot);
ipt.exitFcn     = @(src, evt) exit_bottom_plot_fcn(src, evt,axes_panel_comp.bottom_plot,curr_disp);
ipt.traverseFcn = [];
iptSetPointerBehavior(axes_panel_comp.bottom_plot,ipt);

axes_panel_comp.listeners=[];
rm_axes_interactions([axes_panel_comp.main_axes axes_panel_comp.vaxes axes_panel_comp.haxes]);

setappdata(main_figure,'Axes_panel',axes_panel_comp);

end


function exit_bottom_plot_fcn(src,~,hplot,curr_disp)
set(hplot,'linewidth',0.5);
% setptr(src,curr_disp.get_pointer());
end

function enter_bottom_plot_fcn(src,evt,hplot)
set(src, 'Pointer', 'hand');
set(hplot,'linewidth',2);

end
