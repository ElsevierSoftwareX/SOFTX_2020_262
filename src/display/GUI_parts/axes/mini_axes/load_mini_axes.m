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
    
    delete(mini_axes_comp.echo_obj.main_ax);
    
    rmappdata(main_figure,'Mini_axes');
end


pointerBehavior.enterFcn =  @(figHandle, currentPoint)...
    set(figHandle, 'Pointer', 'fleur');
pointerBehavior.exitFcn  = @(figHandle, currentPoint)...
    set(figHandle, 'Pointer', 'fleur');
pointerBehavior.traverseFcn = @(figHandle, currentPoint)...
    set(figHandle, 'Pointer', 'fleur');

curr_disp=get_esp3_prop('curr_disp');

switch class(parent)
    case  'matlab.ui.Figure'
        d_ax = false;
        d_grid = 'off';
    otherwise
        d_ax = false;
        d_grid = 'on';
end

mini_axes_comp.echo_obj=echo_disp_cl(parent,...
    'pos_in_parent',pos_in_parent,...
    'disp_hori_ax',d_ax,....
    'disp_vert_ax',d_ax,...
    'add_colorbar',false,....
    'disp_grid',d_grid,'ax_tag','mini','cmap',curr_disp.Cmap);

mini_axes_comp.patch_obj=patch(mini_axes_comp.echo_obj.main_ax,'Faces',[],'Vertices',[],'FaceColor',[0 0 0.6],'FaceAlpha',.2,'EdgeColor',[0 0 0.6],'Tag','zoom_area','LineWidth',1);
mini_axes_comp.patch_lim_obj=patch(mini_axes_comp.echo_obj.main_ax,'Faces',[],'Vertices',[],'FaceColor','k','FaceAlpha',0,'EdgeColor','k','Tag','disp_area','LineWidth',0.5,'Linestyle','--');

iptSetPointerBehavior(mini_axes_comp.patch_obj,pointerBehavior);

set(mini_axes_comp.echo_obj.main_ax,'XTickLabels',[],'YTickLabels',[]);

set(mini_axes_comp.echo_obj.echo_surf,'ButtonDownFcn',{@zoom_in_callback_mini_ax,main_figure});
set(mini_axes_comp.echo_obj.echo_bt_surf,'ButtonDownFcn',{@zoom_in_callback_mini_ax,main_figure});
set(mini_axes_comp.patch_obj,'ButtonDownFcn',{@move_patch_mini_axis_grab,main_figure});

if isgraphics(parent,'figure')
    set(parent,'SizeChangedFcn',{@resize_mini_ax,main_figure});
else
    set(mini_axes_comp.echo_obj.main_ax,'ButtonDownFcn',{@move_mini_axis_grab,main_figure});
end

setappdata(main_figure,'Mini_axes',mini_axes_comp);

create_context_menu_mini_echo(main_figure);

end