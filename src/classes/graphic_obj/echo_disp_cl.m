classdef echo_disp_cl < handle
    
    properties
        main_ax 
        vert_ax 
        hori_ax 
        echo_surf matlab.graphics.primitive.Surface
        echo_bt_surf matlab.graphics.primitive.Surface
        bottom_line_plot matlab.graphics.chart.primitive.Line
        colorbar_h matlab.graphics.illustration.ColorBar
        regions_h
        geometry_x = 'samples'
        geometry_y = 'pings'
        offset = true
    end
    
    methods
        function obj = echo_disp_cl(parent_h,varargin)
            p = inputParser;
            
            addRequired(p,'parent_h',@(x) isa(x,'matlab.ui.container.Tab')||isa(x,'matlab.ui.container.Tab')||isa(x,'matlab.ui.Figure')||isempty(x));
            addParameter(p,'geometry_x','pings',@(x) ismember(x,{'pings','meters'}));
            addParameter(p,'geometry_y','samples',@(x) ismember(x,{'samples','depth'}));
            addParameter(p,'disp_vert_ax',true,@islogical);
            addParameter(p,'disp_hori_ax',true,@islogical);
            addParameter(p,'disp_grid','on',@(x) ismember(x,{'off','on'}));
            addParameter(p,'visible_vert','on',@(x) ismember(x,{'off','on'}));
            addParameter(p,'visible_hori','on',@(x) ismember(x,{'off','on'}));
            addParameter(p,'vert_ax_pos','left',@(x) ismember(x,{'left','right'}));
            addParameter(p,'visible_main','on',@(x) ismember(x,{'off','on'}));
            addParameter(p,'pos_in_parent',[0 0 1 1],@isnumeric);
            addParameter(p,'FaceAlpha','flat',@ischar);
            addParameter(p,'FaceColor','k');
            addParameter(p,'AlphaDataMapping','direct',@ischar);
            addParameter(p,'FontSize',9,@isnumeric);
            addParameter(p,'offset',true,@islogical);
            addParameter(p,'disp_colorbar',true,@islogical);
            addParameter(p,'ax_tag','main',@ischar);
            addParameter(p,'uiaxes',false,@islogical);
            parse(p,parent_h,varargin{:});
            
            fields=fieldnames(p.Results);
            for ifi=1:numel(fields)
                if isprop(obj,fields{ifi})
                    obj.(fields{ifi})= p.Results.(fields{ifi});
                end
            end
            
            if isempty(parent_h)
                parent_h = new_echo_figure([],'UiFigureBool',p.Results.uiaxes);
            end
            
            if p.Results.uiaxes
                ax_fcn = @uiaxes;
                tmp = getpixelposition(parent_h);
                if ismember('pos_in_parent',p.UsingDefaults)
                    pos=[0 0 tmp(3:4)];
                end
            else
                ax_fcn =@axes;
                pos = p.Results.pos_in_parent;
            end
            
            
            user_data.geometry_x=obj.geometry_x;
            user_data.geometry_y=obj.geometry_y;
            
            
            obj.main_ax=feval(ax_fcn,'Parent',parent_h,...
                'FontSize',p.Results.FontSize,...
                'Position',pos,...
                'XAxisLocation','bottom',...
                'XLimMode','manual',...
                'YLimMode','manual',...
                'TickLength',[0 0],...
                'XTickLabel',{[]},...
                'YTickLabel',{[]},...
                'XTickMode','manual',...
                'YTickMode','manual',...
                'Box','on',...
                'SortMethod','childorder',...
                'XAxisLocation','top',...
                'XGrid',p.Results.disp_grid,...
                'YGrid',p.Results.disp_grid,...
                'XMinorGrid',p.Results.disp_grid,...
                'YMinorGrid',p.Results.disp_grid,...
                'GridLineStyle','--',...
                'MinorGridLineStyle',':',...
                'NextPlot','add',...
                'YDir','reverse',...
                'Visible',p.Results.visible_main,...
                'ClippingStyle','rectangle',...
                'Interactions',[],...
                'Toolbar',[],...
                'Tag',p.Results.ax_tag,...
                'UserData',user_data);
            
            if p.Results.disp_vert_ax
                switch p.Results.vert_ax_pos
                    case 'right'
                        pos_vert = [pos(1)+pos(3) pos(2) 0 pos(4)];
                        vert_ax_pos = 'left';
                    case 'left'
                       pos_vert = [pos(1) pos(2) 0 pos(4)];
                       vert_ax_pos = 'right';
                end
                obj.vert_ax=feval(ax_fcn,'Parent',parent_h,...
                    'FontSize',p.Results.FontSize,...
                    'Fontweight','Bold',...
                    'Interactions',[],'Toolbar',[],...
                    'Position',pos_vert,...
                    'XAxisLocation','Top',...
                    'YAxisLocation',vert_ax_pos,...
                    'YTickMode','manual',...
                    'TickDir','in',...
                    'visible',p.Results.visible_vert,...
                    'box','on',...
                    'XTickLabel',{[]},...
                    'Xgrid',p.Results.disp_grid,...
                    'Ygrid',p.Results.disp_grid,...
                    'NextPlot','add',...
                    'ClippingStyle','rectangle',...
                    'GridColor',[0 0 0],...
                    'YDir','reverse',...
                    'Tag',p.Results.ax_tag,...
                    'UserData',user_data);
                if  strcmpi(user_data.geometry_y,'depth')
                    obj.vert_ax.YAxis.TickLabelFormat  = '%g m';
                end
            else
                obj.vert_ax =matlab.graphics.axis.Axes.empty;
            end
            
            if p.Results.disp_hori_ax
                obj.hori_ax=feval(ax_fcn,'Parent',parent_h,...
                    'Interactions',[],...
                    'Toolbar',[],...
                    'FontSize',p.Results.FontSize,...
                    'Fontweight','Bold',...
                    'Position',[pos(1) pos(2)+pos(4) pos(3) 0],...
                    'XAxisLocation','bottom',...
                    'YAxisLocation','left',...
                    'TickDir','in',...
                    'XTickMode','manual',...
                    'visible',p.Results.visible_hori,...
                    'box','on',...
                    'YTickLabel',{[]},...
                    'XTickLabelRotation',-90,...
                    'Xgrid',p.Results.disp_grid,...
                    'Ygrid',p.Results.disp_grid,...
                    'ClippingStyle','rectangle',...
                    'NextPlot','add',...
                    'GridColor',[0 0 0],...
                    'SortMethod','childorder',...
                    'Tag',p.Results.ax_tag,...
                    'UserData',user_data);
            else
                obj.hori_ax=matlab.graphics.axis.Axes.empty;
            end
            
            
            
            echo_init=zeros(2,2);
            
            usrdata_echo=init_echo_usrdata();
            
            obj.echo_surf=pcolor(obj.main_ax,echo_init);
            obj.echo_bt_surf=pcolor(obj.main_ax,zeros(size(echo_init),'uint8'));
            
            set(obj.echo_surf,...
                'Facealpha',p.Results.FaceAlpha,...
                'FaceColor',p.Results.FaceAlpha,...
                'LineStyle','none',...
                'AlphaDataMapping',p.Results.AlphaDataMapping,...
                'UserData',usrdata_echo,...
                'Tag',p.Results.ax_tag);
            
            set(obj.echo_bt_surf,...
                'Facealpha',p.Results.FaceAlpha,...
                'FaceColor',p.Results.FaceColor,...
                'LineStyle','none',...
                'AlphaDataMapping',p.Results.AlphaDataMapping,...
                'tag',p.Results.ax_tag);
            
            if p.Results.disp_colorbar
                obj.colorbar_h=colorbar(obj.main_ax,'PickableParts','none','visible','off','fontsize',p.Results.FontSize-2,'Color','k');
                if ~p.Results.uiaxes
                    obj.colorbar_h.UIContextMenu=[];
                end
            else
                obj.colorbar_h = matlab.graphics.illustration.ColorBar.empty();
            end
            
            obj.bottom_line_plot=plot(obj.main_ax,nan,nan,'tag','bottom');
            
            rm_axes_interactions([obj.main_ax obj.vert_ax obj.hori_ax]);
        end

        function tags = get_tags(obj,varargin)
            ax_vert = [obj(:).vert_ax] ;
            tags = cell(1,numel(ax_vert));
            for ui= 1:numel(ax_vert)
             tags{ui}=ax_vert(ui).Tag;
            end
            
            if ~isempty(varargin)
                tags = tags(varargin{1});
            end
        end
        
        
        function ax_vert = get_vert_ax(obj,varargin)
            ax_vert = [obj(:).vert_ax] ;
            if ~isempty(varargin)
                ax_vert = ax_vert(varargin{1});
            end
        end
        
        function bottom_line_plot = get_bottom_line_plot(obj,varargin)
            bottom_line_plot = [obj(:).bottom_line_plot] ;
            if ~isempty(varargin)
                bottom_line_plot = bottom_line_plot(varargin{1});
            end
        end
        
        function ax_hori = get_hori_ax(obj,varargin)
            ax_hori = [obj(:).hori_ax] ;
            if ~isempty(varargin)
                ax_hori = ax_hori(varargin{1});
            end
        end
        
        
        function ax_main = get_main_ax(obj,varargin)
            ax_main = [obj(:).main_ax] ;
            if ~isempty(varargin)
                ax_main = ax_main(varargin{1});
            end
        end
        
        
        function echo_surf = get_echo_surf(obj,varargin)
            echo_surf = [obj(:).echo_surf] ;
            if ~isempty(varargin)
                echo_surf = echo_surf(varargin{1});
            end
        end
        
        function echo_bt_surf = get_echo_bt_surf(obj,varargin)
            echo_bt_surf = [obj(:).echo_bt_surf] ;
            if ~isempty(varargin)
                echo_bt_surf = echo_bt_surf(varargin{1});
            end
        end
        
        function order_echo_stack(obj,varargin)
            
            p = inputParser;
            
            %profile on;
            addRequired(p,'obj',@(x) isa(x,'echo_disp_cl'));
            addParameter(p,'bt_on_top',0);
            
            parse(p,obj,varargin{:});
            echo_im=obj.echo_surf;
            bt_im=obj.echo_bt_surf;
            
            lines=findobj(obj.main_ax,'Type','Line','-not','tag','region');
            text_disp=findobj(obj.main_ax,'Type','Text');
            regions=findobj(obj.main_ax,'tag','region');
            select_area=getappdata(ancestor(obj.main_ax,'Figure'),'SelectArea');
            
            if ~isempty(select_area)
                select_area=select_area.patch_h;
                if ~isempty(select_area)
                    if ~isvalid(select_area)
                        select_area=[];
                    end
                end
            end
                              
            if p.Results.bt_on_top==0 
                zoom_area=findobj(obj.main_ax,'tag','zoom_area','-or','Tag','disp_area');
                uistack([zoom_area;text_disp;lines;select_area;regions;bt_im;echo_im],'top');
            else
                uistack([bt_im;text_disp;lines;select_area;regions;echo_im],'top');
            end
            
            obj.main_ax.Layer='top';
        end
        
    end
    
    
    
end

