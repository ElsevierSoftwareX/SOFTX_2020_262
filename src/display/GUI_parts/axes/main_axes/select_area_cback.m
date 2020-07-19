%% select_area_cback.m
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
% * |src|: TODO: write description and info on variable
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
function select_area_cback(src,~,main_figure)

% main_figure=ancestor(src,'figure');
layer=get_current_layer();
if isempty(layer)
    return;
end

axes_panel_comp=getappdata(main_figure,'Axes_panel');

curr_disp=get_esp3_prop('curr_disp');
if isempty(axes_panel_comp)
    return;
end

ah=axes_panel_comp.echo_obj.main_ax;

switch src.SelectionType
    case 'normal'
        x_lim=get(ah,'xlim');
        y_lim=get(ah,'ylim');
        cp = ah.CurrentPoint;
        xinit = cp(1,1);
        yinit = cp(1,2);
        
        if xinit<x_lim(1)||xinit>x_lim(end)||yinit<y_lim(1)||yinit>y_lim(end)
            return;
        end
        
        update_boat_position(main_figure,round(xinit),1);
        return;
        
    case{'alt' 'extend'}
        
        switch src.SelectionType
            case 'alt'
                
                modifier = get(src,'CurrentModifier');
                control = ismember({'control','shift'},modifier);
                
                if control(1)
                    mode='horizontal';
                else
                    return;
                end
                
            case 'extend'
                mode='rectangular';
        end
        clear_lines(ah);
        delete(findobj(ah,{'Type','line','-and','Tag','SelectLine'},'-or',{'Type','patch','-and','Tag','SelectArea'}));
        
        [cmap,col_ax,col,col_grid,col_bot,col_txt,~]=init_cmap(curr_disp.Cmap);
        
        [trans_obj,idx_freq]=layer.get_trans(curr_disp);
        
        xdata=trans_obj.get_transceiver_pings();
        ydata=trans_obj.get_transceiver_samples();
        
        x_lim=get(ah,'xlim');
        y_lim=get(ah,'ylim');
        cp = ah.CurrentPoint;
        xinit = cp(1,1);
        yinit = cp(1,2);
        
        if xinit<x_lim(1)||xinit>x_lim(end)||yinit<y_lim(1)||yinit>y_lim(end)
            return;
        end
        
        switch mode
            case 'rectangular'
                xinit = cp(1,1);
                yinit = cp(1,2);
            case 'horizontal'
                xinit = xdata(1);
                yinit = cp(1,2);
            case 'vertical'
                xinit = cp(1,1);
                yinit = ydata(1);
        end
        
        
        x_box=xinit;
        y_box=yinit;
        
        
        hp=line(x_box,y_box,'color',col,'linewidth',1,'parent',ah,'LineStyle','--','Tag','SelectLine');
        
        
        replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',2,'interaction_fcn',@wbmcb);
        replace_interaction(main_figure,'interaction','WindowButtonUpFcn','id',2,'interaction_fcn',@wbucb);
        
        
    case 'open'
        clear_lines(ah);
        
        select_area=getappdata(main_figure,'SelectArea');
        delete(select_area.patch_h);
        delete(select_area.uictxt_menu_h);
        select_area.patch_h=[];
        select_area.uictxt_menu_h=[];
        setappdata(main_figure,'SelectArea',select_area);
        
        layer.rm_curves_per_ID('select_area');
        update_multi_freq_disp_tab(main_figure,'sv_f',0);
        update_multi_freq_disp_tab(main_figure,'ts_f',0);
        return;
end




    function wbmcb(~,~)
        cp = ah.CurrentPoint;
        
        switch mode
            case 'rectangular'
                X = [xinit,cp(1,1)];
                Y = [yinit,cp(1,2)];
            case 'horizontal'
                X = [xinit,xdata(end)];
                Y = [yinit,cp(1,2)];
            case 'vertical'
                X = [xinit,cp(1,1)];
                Y = [yinit,ydata(end)];
                
        end
        
        x_min=nanmin(X);
        x_min=nanmax(xdata(1),x_min);
        
        x_max=nanmax(X);
        x_max=nanmin(xdata(end),x_max);
        
        y_min=nanmin(Y);
        y_min=nanmax(y_min,ydata(1));
        
        y_max=nanmax(Y);
        y_max=nanmin(y_max,ydata(end));
        
        x_box=([x_min x_max  x_max x_min x_min]);
        y_box=([y_max y_max y_min y_min y_max]);
        
        set(hp,'XData',x_box,'YData',y_box);
        
        
    end

    function wbucb(src,~)
        replace_interaction(main_figure,'interaction','WindowButtonMotionFcn','id',2);
        replace_interaction(main_figure,'interaction','WindowButtonUpFcn','id',2);
        
        delete(hp);
        
        switch mode
            case 'horizontal'
                [trans_obj,idx_freq]=layer.get_trans(curr_disp);
                x=trans_obj.get_transceiver_pings();
                x_box=([x(1) x(end)  x(end) x(1) x(1)]);
            case 'vertical'
            otherwise
        end
        
        if length(x_box)<4||length(y_box)<4
            return;
        end
        hp_a=patch(ah,'XData',x_box(1:4),'YData',y_box(1:4),'FaceColor',col,'tag','SelectArea','FaceAlpha',0.5,'EdgeColor',col);
        
        delete(findobj(ancestor(ah,'figure'),'Type','UiContextMenu','-and','Tag','RegionContextMenu','-and','UserData','select_area'));
        
        select_area.uictxt_menu_h=create_region_context_menu(hp_a,main_figure,hp_a);
        
        enterFcn =  @(figHandle, currentPoint)...
            set(figHandle, 'Pointer', 'fleur');
        iptSetPointerBehavior(hp_a,enterFcn);
        
        set(hp_a,'ButtonDownFcn',{@move_patch_select,main_figure});
        
        select_area.patch_h=hp_a;
        
        setappdata(main_figure,'SelectArea',select_area);
        
    end

end