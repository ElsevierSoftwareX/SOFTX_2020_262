function undock_mini_axes_callback(~,~,main_figure,dest)
%profile on;
layer=get_current_layer();
if isempty(layer)
    return;
end

mini_axes_comp=getappdata(main_figure,'Mini_axes');
if ~isempty(mini_axes_comp)
    mini_axes_comp.link_props=[];
end


switch dest
    case 'main_figure'
        pos_out=[0 0 1 0.77];
        disp_tab_comp=getappdata(main_figure,'Display_tab');
        parent=disp_tab_comp.display_tab;
        mini_axes_comp=getappdata(main_figure,'Mini_axes');
        if ~isempty(mini_axes_comp)&&isvalid(mini_axes_comp.echo_obj.main_ax)
            if ~isa(mini_axes_comp.echo_obj.main_ax.Parent,'matlab.ui.container.Tab')
                delete(mini_axes_comp.echo_obj.main_ax.Parent);
            end
        end
    otherwise                
        pos_fig=[0 0.1 1 0.8];
        pos_out=[0 0 1 1];
        parent=new_echo_figure(main_figure,...
            'Units','normalized',...
            'Position',pos_fig,...
            'Name','Overview',...   
            'Resize','on',...
            'CloseRequestFcn',@close_min_axis,...
            'Tag','mini_ax');
        iptPointerManager(parent);
        %delete(mini_axes_comp.echo_obj.main_ax);
        initialize_interactions_mini_ax(parent,main_figure);
end

load_mini_axes(main_figure,parent,pos_out);
update_axis(main_figure,1,'main_or_mini','mini');
set_alpha_map(main_figure,'main_or_mini','mini');
update_cmap(main_figure);
init_link_prop(main_figure);
display_regions(main_figure,'mini');
display_bottom(main_figure);

% profile off;
% profile viewer;

end