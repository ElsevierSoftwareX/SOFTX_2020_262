%% load_mini_axes.m
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
% * |parent|: TODO: write description and info on variable
% * |pos_in_parent|: TODO: write description and info on variable
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
function load_mini_axes(main_figure,parent,pos_in_parent)

if isappdata(main_figure,'Mini_axes')
    mini_axes_comp=getappdata(main_figure,'Mini_axes');
    
    delete(mini_axes_comp.mini_ax);
    
    rmappdata(main_figure,'Mini_axes');
end


pointerBehavior.enterFcn =  @(figHandle, currentPoint)...
    set(figHandle, 'Pointer', 'fleur');
pointerBehavior.exitFcn  = @(figHandle, currentPoint)...
    set(figHandle, 'Pointer', 'fleur');
pointerBehavior.traverseFcn = @(figHandle, currentPoint)...
    set(figHandle, 'Pointer', 'fleur');


user_data.geometry_y='samples';
user_data.geometry_x='pings';


mini_axes_comp.mini_ax=axes('Parent',parent,'Interactions',[],'Toolbar',[],...
    'Units','normalized','box','on',...
    'Position',pos_in_parent,'visible','on','NextPlot','add','box','on','tag','mini','ClippingStyle','rectangle','UserData',user_data);
rm_axes_interactions(mini_axes_comp.mini_ax);
%iptSetPointerBehavior(mini_axes_comp.mini_ax,pointerBehavior);
curr_disp=get_esp3_prop('curr_disp');
echo_init=ones(2,2);

usrdata=init_echo_usrdata();

switch curr_disp.EchoType
    case 'image'
        mini_axes_comp.mini_echo=image(echo_init,'Parent',mini_axes_comp.mini_ax,'tag','echo','AlphaData',0,'CDataMapping','scaled','AlphaDataMapping','direct','UserData',usrdata);
        mini_axes_comp.mini_echo_bt=image(echo_init,'Parent',mini_axes_comp.mini_ax,'tag','bad_transmits','AlphaData',0,'AlphaDataMapping','direct');
    case 'surface'
        mini_axes_comp.mini_echo=pcolor(mini_axes_comp.mini_ax,echo_init);
        set(mini_axes_comp.mini_echo,'Facealpha','flat','FaceColor','Flat','LineStyle','none','AlphaDataMapping','direct','tag','echo','VertexNormalsMode','manual','UserData',usrdata);
        mini_axes_comp.mini_echo_bt=pcolor(mini_axes_comp.mini_ax,echo_init);
        set(mini_axes_comp.mini_echo_bt,'Facealpha','flat','FaceColor','Flat','LineStyle','none','AlphaDataMapping','direct','tag','bad_transmits','VertexNormalsMode','manual');
end


mini_axes_comp.bottom_plot=plot(mini_axes_comp.mini_ax,nan,nan,'tag','bottom');
mini_axes_comp.patch_obj=patch(mini_axes_comp.mini_ax,'Faces',[],'Vertices',[],'FaceColor',[0 0 0.6],'FaceAlpha',.2,'EdgeColor',[0 0 0.6],'Tag','zoom_area','LineWidth',1);
mini_axes_comp.patch_lim_obj=patch(mini_axes_comp.mini_ax,'Faces',[],'Vertices',[],'FaceColor','k','FaceAlpha',0,'EdgeColor','k','Tag','disp_area','LineWidth',0.5,'Linestyle','--');

iptSetPointerBehavior(mini_axes_comp.patch_obj,pointerBehavior);

set(mini_axes_comp.mini_ax,'XTickLabels',[],'YTickLabels',[]);

set(mini_axes_comp.patch_obj,'ButtonDownFcn',{@move_patch_mini_axis_grab,main_figure});
set(mini_axes_comp.mini_echo,'ButtonDownFcn',{@zoom_in_callback_mini_ax,main_figure});
set(mini_axes_comp.mini_echo_bt,'ButtonDownFcn',{@zoom_in_callback_mini_ax,main_figure});

if isgraphics(parent,'figure')
    set(parent,'SizeChangedFcn',{@resize_mini_ax,main_figure});
else
    set(mini_axes_comp.mini_ax,'ButtonDownFcn',{@move_mini_axis_grab,main_figure});
end

setappdata(main_figure,'Mini_axes',mini_axes_comp);

create_context_menu_mini_echo(main_figure);

end