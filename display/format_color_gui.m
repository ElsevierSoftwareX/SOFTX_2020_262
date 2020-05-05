function format_color_gui(fig,font_choice,cmap,varargin)
%background_col=get(groot,'defaultUicontrolBackgroundColor');

%-- Alex change: BackgroundColor proprety of uitab doesn't like names and
%prefer RGB triplet (at least on R0216b)
% background_col = 'white';

if nargin>3
    [cmap_t,background_col,col_lab,col_grid,col_bot,col_txt,col_tracks]=init_cmap(cmap);
    colormap(fig,cmap_t);
else
    background_col=[0.98 0.98 1];
    col_lab=[0 0 0.2];
end
for i=1:length(fig)
    if ~isvalid(fig(i))
        continue;
    end
    if isprop(fig(i),'Color')
        set(fig(i),'Color',background_col);
    end
    if isprop(fig(i),'BackgroundColor')
        set(fig(i),'BackgroundColor',background_col);
    end
    
    c_obj=findobj(fig(i),'Type','colorbar');
    set(c_obj,'Color',col_lab);
    
    panel_obj=findobj(fig(i),'Type','uipanel');
    set(panel_obj,'BackgroundColor',background_col,'bordertype','none','ForegroundColor',col_lab);

     tab_obj=findobj(fig(i),'Type','uitab','-property','BackgroundColor');
     set(tab_obj,'BackgroundColor',background_col);
     if nargin>3
         ax_obj=findobj(fig(i),'Type','axes');
         set(ax_obj,'Color',background_col,'GridColor',...
             col_grid,'MinorGridColor',col_grid,'XColor',col_lab,'YColor',col_lab);
         set(ax_obj.Title,'Color',col_lab);
         l_obj=findobj(fig(i),'Type','legend');
         set(l_obj,'TextColor',col_lab,'Color',background_col);
         
     end
    buttongroup_obj=findobj(fig(i),'Type','uibuttongroup','-property','BackgroundColor');
    set(buttongroup_obj,'BackgroundColor',background_col,'ForegroundColor',col_lab);
    
    control_obj=findobj(fig(i),'Type','uicontrol','-not',{'Style','popupmenu','-or','Style','edit','-or','Style','pushbutton'});
    %control_obj=findobj(fig(i),'Type','uicontrol');
    set(control_obj,'BackgroundColor',background_col);
        

    
    load_bar_comp=getappdata(fig(i),'Loading_bar');
    if ~isempty(load_bar_comp)
        load_bar_comp.progress_bar.progaxes.Color=background_col;
        load_bar_comp.progress_bar.progaxes.GridColor=col_lab;
    end
    
    if ~isempty(font_choice)
        if strcmp(fig(i).Tag,'font_choice')
            continue;
        end
        text_obj=findobj(fig(i),'-property','FontName');
        if ~isempty(text_obj)
            set(text_obj,'FontName',font_choice);
        end
    end

    % size_obj=findobj(fig,'-property','FontSize');
    % set(size_obj,'FontSize',12);
end
end