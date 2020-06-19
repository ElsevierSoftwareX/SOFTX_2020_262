%% move_patch_mini_axis_grab.m
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
function move_patch_mini_axis_grab(~,~,main_figure)

mini_axes_comp=getappdata(main_figure,'Mini_axes');
axes_panel_comp=getappdata(main_figure,'Axes_panel');
main_axes=axes_panel_comp.main_axes;
patch_obj=mini_axes_comp.patch_obj;
%curr_disp = get_esp3_prop('curr_disp');
ah=mini_axes_comp.mini_ax;

if isempty(patch_obj.Vertices)
    return;
end

current_fig=gcf;

set(mini_axes_comp.mini_echo,'ButtonDownFcn','');
set(mini_axes_comp.mini_echo_bt,'ButtonDownFcn','');


if strcmp(current_fig.SelectionType,'normal')
    cp = ah.CurrentPoint;
    x0 = cp(1,1);
    y0 = cp(1,2);
    x_lim=get(ah,'xlim');
    y_lim=get(ah,'ylim');
    
    
    dx_patch=nanmax(patch_obj.Vertices(:,1))-nanmin(patch_obj.Vertices(:,1));
    dy_patch=nanmax(patch_obj.Vertices(:,2))-nanmin(patch_obj.Vertices(:,2));
    %replace_interaction(current_fig,'interaction','WindowButtonMotionFcn','id',1);
    replace_interaction(current_fig,'interaction','WindowButtonMotionFcn','id',2,'interaction_fcn',@wbmcb,'Pointer','fleur');
    replace_interaction(current_fig,'interaction','WindowButtonUpFcn','id',2,'interaction_fcn',@wbucb);   
end
    function wbmcb(~,~)
        cp = ah.CurrentPoint;
        x1 = cp(1,1);
        y1 = cp(1,2);
        
        
        d_move=[x1 y1]-[x0 y0];
        
        new_vert=patch_obj.Vertices+repmat(d_move,4,1);
        
        if nansum(new_vert(:,1)<x_lim(1))>0
            new_vert(:,1)=[x_lim(1) x_lim(1)+dx_patch x_lim(1)+dx_patch x_lim(1)];
        end
        
        if nansum(new_vert(:,1)>x_lim(2))>0
            new_vert(:,1)=[x_lim(2)-dx_patch x_lim(2) x_lim(2) x_lim(2)-dx_patch];
        end
        
        if nansum(new_vert(:,2)<y_lim(1))>0
            new_vert(:,2)=[y_lim(1) y_lim(1) y_lim(1)+dy_patch y_lim(1)+dy_patch];
        end
        
        if nansum(new_vert(:,2)>y_lim(2))>0
            new_vert(:,2)=[y_lim(2)-dy_patch y_lim(2)-dy_patch y_lim(2) y_lim(2)];
        end
        
        patch_obj.Vertices=new_vert;
        x0=x1;
        y0=y1;
        %all(inpolygon(new_vert(:,1),new_vert(:,2),patch_obj_lim.Vertices(:,1),patch_obj_lim.Vertices(:,2)))
%         if all(inpolygon(new_vert(:,1),new_vert(:,2),mini_axes_comp.patch_lim_obj.Vertices(:,1),mini_axes_comp.patch_lim_obj.Vertices(:,2)))&&curr_disp.DispSecFreqs==0
%             set(main_axes,'xlim',[nanmin(patch_obj.Vertices(:,1)) nanmax(patch_obj.Vertices(:,1))]);
%             set(main_axes,'ylim',[nanmin(patch_obj.Vertices(:,2)) nanmax(patch_obj.Vertices(:,2))]);
%             drawnow;
%         end
        
        
    end

    function wbucb(~,~)
        %replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',1,'interaction_fcn',{@update_info_panel,0});
        replace_interaction(current_fig,'interaction','WindowButtonMotionFcn','id',2);
        replace_interaction(current_fig,'interaction','WindowButtonUpFcn','id',2);
        
        
        set(main_axes,'xlim',[nanmin(patch_obj.Vertices(:,1)) nanmax(patch_obj.Vertices(:,1))]);
        set(main_axes,'ylim',[nanmin(patch_obj.Vertices(:,2)) nanmax(patch_obj.Vertices(:,2))]);
        drawnow;
        set(mini_axes_comp.mini_echo,'ButtonDownFcn',{@zoom_in_callback_mini_ax,main_figure});
        set(mini_axes_comp.mini_echo_bt,'ButtonDownFcn',{@zoom_in_callback_mini_ax,main_figure});
        
        
        
    end
end


