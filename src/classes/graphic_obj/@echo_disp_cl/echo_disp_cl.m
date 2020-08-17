classdef echo_disp_cl < handle
    
    properties
        tag = '';
        t_size = 8;
        main_ax
        vert_ax
        hori_ax
        pos_in_parent = [0 0 1 1]
        echo_surf matlab.graphics.primitive.Surface
        echo_bt_surf matlab.graphics.primitive.Surface
        bottom_line_plot matlab.graphics.chart.primitive.Line
        colorbar_h matlab.graphics.illustration.ColorBar
        regions_h
        offset = true
        echo_usrdata=init_echo_usrdata()
        linked_prop = []
    end
    
    methods
        function obj = echo_disp_cl(parent_h,varargin)
            p = inputParser;
            
            addRequired(p,'parent_h',@(x) isa(x,'matlab.ui.container.Tab')||isa(x,'matlab.ui.container.Tab')||isa(x,'matlab.ui.Figure')||isempty(x));
            addParameter(p,'geometry_x','pings',@(x) ismember(x,{'pings','meters'}));
            addParameter(p,'geometry_y','samples',@(x) ismember(x,{'samples','depth'}));
            addParameter(p,'cmap','ek60',@ischar);
            addParameter(p,'disp_vert_ax',true,@islogical);
            addParameter(p,'disp_hori_ax',true,@islogical);
            addParameter(p,'disp_colorbar',true,@islogical);
            addParameter(p,'add_colorbar',true,@islogical);
            addParameter(p,'disp_grid','on',@(x) ismember(x,{'off','on'}));
            addParameter(p,'visible_vert','on',@(x) ismember(x,{'off','on'}));
            addParameter(p,'visible_hori','on',@(x) ismember(x,{'off','on'}));
            addParameter(p,'y_ax_pos','left',@(x) ismember(x,{'left','right'}));
            addParameter(p,'x_ax_pos','top',@(x) ismember(x,{'top','bottom'}));
            addParameter(p,'visible_fig','on',@(x) ismember(x,{'off','on'}));
            addParameter(p,'visible_main','on',@(x) ismember(x,{'off','on'}));
            addParameter(p,'pos_in_parent',[0 0 1 1],@isnumeric);
            addParameter(p,'FaceAlpha','flat',@ischar);
            addParameter(p,'FaceColor','k');
            addParameter(p,'YDir','reverse');
            addParameter(p,'AlphaDataMapping','direct',@ischar);
            addParameter(p,'FontSize',9,@isnumeric);
            addParameter(p,'offset',true,@islogical);
            addParameter(p,'tag','',@ischar);
            addParameter(p,'ax_tag','',@ischar);
            addParameter(p,'uiaxes',false,@islogical);
            addParameter(p,'link_ax',false,@islogical);
            addParameter(p,'V_axes_ratio',0,@isnumeric);
            addParameter(p,'H_axes_ratio',0,@isnumeric);
            addParameter(p,'echo_usrdata',init_echo_usrdata(),@isstruct);
            parse(p,parent_h,varargin{:});
            
            fields=fieldnames(p.Results);
            for ifi=1:numel(fields)
                if isprop(obj,fields{ifi})
                    obj.(fields{ifi})= p.Results.(fields{ifi});
                end
            end
            
            if isempty(parent_h)||~isvalid(parent_h)
                link_ax = true;
                parent_h = new_echo_figure(get_esp3_prop('main_figure'),'UiFigureBool',p.Results.uiaxes,'visible',p.Results.visible_fig);
            else
                link_ax = false;
            end
            
            [cmap,col_ax,col_lab,col_grid,col_bot,col_txt,col_tracks]=init_cmap(p.Results.cmap);
            
            if p.Results.uiaxes&&will_it_work(parent_h,[],true)
                ax_fcn = @uiaxes;
                tmp = getpixelposition(parent_h);
                if ismember('pos_in_parent',p.UsingDefaults)
                    pos=[0 0 tmp(3:4)];
                end
            else
                ax_fcn =@axes;
                pos = p.Results.pos_in_parent;
            end
            
            obj.pos_in_parent = pos;
                     
            obj.echo_usrdata.ax_tag = p.Results.ax_tag;
            obj.echo_usrdata.geometry_x=p.Results.geometry_x;
            obj.echo_usrdata.geometry_y=p.Results.geometry_y;
            
            obj.main_ax=feval(ax_fcn,...
                'Parent',parent_h,...
                'Color',col_ax,...
                'GridColor',col_grid,...
                'MinorGridColor',col_grid,...
                'XColor',col_lab,...
                'YColor',col_lab,...
                'FontSize',p.Results.FontSize,...
                'XAxisLocation',p.Results.x_ax_pos,...
                'YAxisLocation',p.Results.y_ax_pos,...
                'XLimMode','manual',...
                'YLimMode','manual',...
                'TickLength',[0 0],...
                'XTickLabel',{[]},...
                'YTickLabel',{[]},...
                'XTickMode','manual',...
                'YTickMode','manual',...
                'Box','on',...
                'SortMethod','childorder',...
                'XGrid',p.Results.disp_grid,...
                'YGrid',p.Results.disp_grid,...
                'XMinorGrid',p.Results.disp_grid,...
                'YMinorGrid',p.Results.disp_grid,...
                'GridLineStyle','--',...
                'MinorGridLineStyle',':',...
                'NextPlot','add',...
                'YDir',p.Results.YDir,...
                'visible','off',...
                'ClippingStyle','rectangle',...
                'Interactions',[],...
                'Toolbar',[],...
                'Colormap',cmap,...
                'Tag',p.Results.ax_tag);
            
            
            
            switch  p.Results.x_ax_pos
                case 'bottom'
                    x_ax_pos = 'top';
                case'top'
                    x_ax_pos = 'bottom';
            end

            switch  p.Results.y_ax_pos
                case 'right'
                    y_ax_pos = 'left';
                case'left'
                    y_ax_pos = 'right';
            end
            
                           
            if p.Results.disp_vert_ax
                obj.vert_ax=feval(ax_fcn,'Parent',parent_h,...
                    'Color',col_ax,...
                    'GridColor',col_grid,...
                    'MinorGridColor',col_grid,...
                    'XColor',col_lab,...
                    'YColor',col_lab,...
                    'FontSize',p.Results.FontSize,...
                    'Fontweight','Bold',...
                    'Interactions',[],...
                    'Toolbar',[],...
                    'Ticklength' ,[0.005 0.0100],...
                    'XAxisLocation',x_ax_pos,...
                    'YAxisLocation',y_ax_pos,...
                    'YTickMode','manual',...
                    'TickDir','in',...
                    'visible','off',...
                    'box','on',...
                    'XTickLabel',{[]},...
                    'Xgrid',p.Results.disp_grid,...
                    'Ygrid',p.Results.disp_grid,...
                    'NextPlot','add',...
                    'ClippingStyle','rectangle',...
                    'YDir',p.Results.YDir,...
                    'Tag',p.Results.ax_tag);
                
                if  strcmpi(obj.echo_usrdata.geometry_y,'depth')
                    obj.vert_ax.YAxis.TickLabelFormat  = '%g m';
                end
            else
                obj.vert_ax =matlab.graphics.axis.Axes.empty;
            end
            
            if p.Results.disp_hori_ax
                obj.hori_ax=feval(ax_fcn,'Parent',parent_h,...
                    'Color',col_ax,...
                    'GridColor',col_grid,...
                    'MinorGridColor',col_grid,...
                    'XColor',col_lab,...
                    'YColor',col_lab,...
                    'Interactions',[],...
                    'Ticklength' ,[0.005 0.0100],...
                    'Toolbar',[],...
                    'FontSize',p.Results.FontSize,...
                    'Fontweight','Bold',...
                    'XAxisLocation',x_ax_pos,...
                    'YAxisLocation',y_ax_pos,...
                    'TickDir','in',...
                    'XTickMode','manual',...
                    'Visible','off',...
                    'Box','on',...
                    'YTickLabel',{[]},...
                    'XTickLabelRotation',-90,...
                    'Xgrid',p.Results.disp_grid,...
                    'Ygrid',p.Results.disp_grid,...
                    'ClippingStyle','rectangle',...
                    'NextPlot','add',...
                    'Tag',p.Results.ax_tag,...
                    'SortMethod','childorder');
            else
                obj.hori_ax=matlab.graphics.axis.Axes.empty();
            end
            
            
           
            if p.Results.add_colorbar
                obj.colorbar_h=colorbar(obj.main_ax,...
                    'PickableParts','none',...
                    'fontsize',p.Results.FontSize-2,...
                    'Color','k',...
                    'Visible','off',...
                    'Tag',p.Results.ax_tag);
            else
                obj.colorbar_h = matlab.graphics.illustration.ColorBar.empty();
            end

             if ~isempty(obj.colorbar_h)&&(will_it_work(parent_h,9.8,true)||will_it_work(parent_h,[],false))
                 obj.colorbar_h.UIContextMenu=[];
            end
             

            obj.bottom_line_plot=plot(obj.main_ax,nan,nan,'Tag','bottom','Color',col_bot);
            
            rm_axes_interactions([obj.main_ax obj.vert_ax obj.hori_ax]);
            
                 
             if ~isempty(obj.main_ax)&&strcmpi(p.Results.visible_main,'on')
                obj.main_ax.Visible ='on';
            end
            
            if ~isempty(obj.colorbar_h)&&p.Results.disp_colorbar
                obj.colorbar_h.Visible ='on';
            end   
            if ~isempty(obj.vert_ax)&&strcmpi(p.Results.visible_vert,'on')
                obj.vert_ax.Visible ='on';
            end
            if ~isempty(obj.hori_ax)&&strcmpi(p.Results.visible_hori,'on')
                obj.hori_ax.Visible ='on';
            end
            obj.set_axes_position(p.Results.V_axes_ratio,p.Results.H_axes_ratio);
            
            echo_init=zeros(2,2);
            
            obj.echo_surf=pcolor(obj.main_ax,echo_init);
            obj.echo_bt_surf=pcolor(obj.main_ax,zeros(size(echo_init),'uint8'));
            
            set(obj.echo_surf,...
                'Facealpha',p.Results.FaceAlpha,...
                'FaceColor',p.Results.FaceAlpha,...
                'LineStyle','none',...
                'AlphaDataMapping',p.Results.AlphaDataMapping,...
                'UserData',obj.echo_usrdata,...
                'Tag',p.Results.ax_tag);
            
            set(obj.echo_bt_surf,...
                'Facealpha',p.Results.FaceAlpha,...
                'FaceColor',col_lab,...
                'LineStyle','none',...
                'AlphaDataMapping',p.Results.AlphaDataMapping,...
                'Tag',p.Results.ax_tag);
            
            if link_ax||p.Results.link_ax
                obj.link_prop_ax();
            end
        end
        
        function parent_fig = get_parent_figure(obj)
            parent_fig = ancestor(obj.main_ax,'figure');
        end
        
        function link_prop_ax(obj)
            
            obj.linked_prop.general=linkprop([obj.main_ax...
                obj.hori_ax obj.vert_ax],...
                {'YColor','XColor','GridLineStyle','Color','GridColor','MinorGridColor'});
            
            obj.linked_prop.ydir=linkprop([obj.main_ax obj.vert_ax],...
                {'YDir'});
            
            obj.linked_prop.xtick=linkprop([obj.main_ax obj.hori_ax],{'XTick' 'XLim'});
            obj.linked_prop.ytick=linkprop([obj.main_ax obj.vert_ax],{'YTick' 'YLim'});
            
            
            
        end
        
        function tags = get_tags(obj,varargin)
            
            tags = cell(1,numel(obj));
            for ui= 1:numel(obj)
                tags{ui}=obj(ui).echo_usrdata.ax_tag;
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
            
            if will_it_work(obj.main_ax,[],false)
                if p.Results.bt_on_top==0
                    zoom_area=findobj(obj.main_ax,'tag','zoom_area','-or','Tag','disp_area');
                    uistack([zoom_area;text_disp;lines;select_area;regions;bt_im;echo_im],'top');
                else
                    uistack([bt_im;text_disp;lines;select_area;regions;echo_im],'top');
                end
            end
            obj.main_ax.Layer='top';
        end
        
        
        function update_echo_grid(obj,trans_obj,varargin)
            
            p = inputParser;
            addRequired(p,'obj',@(x) isa(x,'echo_disp_cl'));
            addRequired(p,'trans_obj',@(x) isa(x,'transceiver_cl'))
            addParameter(p,'curr_disp',curr_state_disp_cl(),@(x) isa(x,'curr_state_disp_cl'));
            
            parse(p,obj,trans_obj,varargin{:});
            
            curr_disp = p.Results.curr_disp;
            
            [dx,dy]=curr_disp.get_dx_dy();
            
            idx_pings=round(obj.echo_surf.XData);
            
           
            switch curr_disp.Xaxes_current
                case 'seconds'
                    xdata_grid=trans_obj.Time(idx_pings);
                    xdata_grid=xdata_grid*(24*60*60);
                case 'pings'
                    xdata_grid=trans_obj.get_transceiver_pings(idx_pings);
                case 'meters'
                    xdata_grid=trans_obj.GPSDataPing.Dist;
                    if  ~any(~isnan(trans_obj.GPSDataPing.Lat))
                        disp('No GPS Data');
                        curr_disp.Xaxes_current='pings';
                        curr_disp.init_grid_val(trans_obj);
                        [dx,dy]=curr_disp.get_dx_dy();
                        xdata_grid=trans_obj.get_transceiver_pings(idx_pings);
                    else
                        xdata_grid=xdata_grid(idx_pings);
                    end
                otherwise
                    xdata_grid=trans_obj.get_transceiver_pings(idx_pings);
            end
            
            if dx == 0
                dx = nanmean(diff(xdata_grid)/10);
            end
            
            
            idx_xticks=find((diff(rem(xdata_grid,dx))<0))+1;
            idx_minor_xticks=find((diff(rem(xdata_grid+dx/2,dx))<0))+1;
            idx_minor_xticks=setdiff(idx_minor_xticks,idx_xticks);
            
            obj.main_ax.XTick=idx_pings(idx_xticks);
            obj.main_ax.XAxis.MinorTickValues=idx_pings(idx_minor_xticks);
            
            switch obj.echo_usrdata.geometry_y
                case {'depth' 'range'}
                    ylim=obj.echo_usrdata.ylim;
                    ydata_grid = round(ylim(1):curr_disp.Grid_y/100:ylim(2));
                    idx_r = ydata_grid;
                otherwise
                    idx_r=round(obj.echo_surf.YData);
                    ydata_grid=trans_obj.get_transceiver_range(idx_r);
            end
            
            if dy == 0
                dy = nanmean(diff(ydata_grid)/10);
            end
            
            
            idx_yticks=find((diff(rem(ydata_grid,dy))<0))+1;
            idx_minor_yticks=find((diff(rem(ydata_grid+dy/2,dy))<0))+1;
            
            idx_minor_yticks=setdiff(idx_minor_yticks,idx_yticks);
            obj.main_ax.YTick=idx_r(idx_yticks);
            obj.main_ax.YAxis.MinorTickValues=idx_r(idx_minor_yticks);
            
            fmt=' %.0fm';
            
            yl=num2cell(floor(ydata_grid(idx_yticks)/dy)*dy);
            y_labels=cellfun(@(x) num2str(x,fmt),yl,'UniformOutput',0);
            
            set(obj.vert_ax,'yticklabels',y_labels);
            
            str_start=' ';
            xl=num2cell((xdata_grid(idx_xticks)/dx)*dx);
            
            switch lower(curr_disp.Xaxes_current)
                case 'seconds'
                    h_fmt='HH:MM:SS';
                    x_labels=cellfun(@(x) datestr(x/(24*60*60),h_fmt),xl,'UniformOutput',0);
                case 'pings'
                    fmt=[str_start '%.0f'];
                    obj.hori_ax.XTickLabelMode='auto';
                    x_labels=cellfun(@(x) num2str(x,fmt),xl,'UniformOutput',0);
                case 'meters'
                    obj.hori_ax.XTickLabelMode='auto';
                    fmt=[str_start '%.0fm'];
                    x_labels=cellfun(@(x) num2str(x,fmt),xl,'UniformOutput',0);
                otherwise
                    obj.hori_ax.XTickLabelMode='auto';
                    fmt=[str_start '%.0f'];
                    x_labels=cellfun(@(x) num2str(x,fmt),xl,'UniformOutput',0);
            end
            
            set(obj.hori_ax,'xticklabels',x_labels);
            
        end
        
        
        function  set_echo_alphamap(obj,trans_obj,varargin)
            
            p = inputParser;
            addRequired(p,'obj',@(x) isa(x,'echo_disp_cl'));
            addRequired(p,'trans_obj',@(x) isa(x,'transceiver_cl'))
            addParameter(p,'update_bt',1);
            addParameter(p,'update_under_bot',1);
            addParameter(p,'update_cmap',1);
            addParameter(p,'curr_disp',curr_state_disp_cl(),@(x) isa(x,'curr_state_disp_cl')||isempty(x));
            parse(p,obj,trans_obj,varargin{:});
            
            curr_disp = p.Results.curr_disp;
            min_axis=curr_disp.Cax(1);
            
            echo_im=obj.get_echo_surf();
            echo_ax=obj.get_main_ax();
            echo_im_bt=obj.get_echo_bt_surf();
            
            data=double(get(echo_im,'CData'));
            xdata=double(get(echo_im,'XData'));
            
            xdata_ori=xdata;
            
            idx_pings=obj.echo_usrdata.Idx_pings;
            
            idx_r=obj.echo_usrdata.Idx_r(:);
            
            prec='uint8';
            
            switch obj.echo_usrdata.geometry_y
                case'samples'
                    ydata=idx_r+1/2;
                case 'depth'
                    ydata=double(get(echo_im,'YData'));
            end
            
            if p.Results.update_under_bot>0
                alpha_map=ones(size(data),prec)*6;
                switch obj.echo_usrdata.geometry_y
                    case'samples'
                        bot_vec_red=trans_obj.get_bottom_idx(idx_pings);
                    case 'depth'
                        bot_vec_red=trans_obj.get_bottom_depth(idx_pings);
                    case 'range'
                        bot_vec_red=trans_obj.get_bottom_range(idx_pings);
                end
                
                idx_bot_red=bsxfun(@le,bot_vec_red,ydata);
                alpha_map(idx_bot_red)=2;
            else
                alpha_map=double(get(echo_im,'AlphaData'));
            end
            
            %alpha_map(:,idx_bad_red)=3;
            
            if p.Results.update_bt>0
                
                idxBad=find(trans_obj.Bottom.Tag==0);
                idx_bad_red=(ismember(idx_pings,idxBad));
                
                alpha_map_bt=zeros(size(data),prec);
                alpha_map_bt(:,idx_bad_red)=3;
                
                mask_sp=trans_obj.get_spikes(idx_r,idx_pings);
                
                if~isempty(mask_sp)&&all(size(mask_sp)==size(data))
                    alpha_map_bt(mask_sp>0)=5;
                end
                
                set(echo_im_bt,'XData',xdata_ori,'YData',ydata,'CData',alpha_map_bt,'ZData',zeros(size(alpha_map_bt),'uint8'),'AlphaData',single(alpha_map_bt));
            end
            
            if p.Results.update_cmap>0
                alpha_map(data<min_axis|isnan(data))=1;
                set(echo_ax,'CLim',curr_disp.Cax);
            end
            
            if p.Results.update_cmap>0||p.Results.update_under_bot>0
                set(echo_im,'AlphaData',single(alpha_map));
            end
            
        end
        
        function [ping_range,sample_range] = get_ping_sample_range(echo_obj,trans_obj)
                
            switch echo_obj.echo_usrdata.geometry_x
                case 'pings'
                    xdata=trans_obj.get_transceiver_pings();
                case 'seconds'
                    xdata=trans_obj.get_transceiver_time();
                case 'meters'
                    xdata=trans_obj.GPSDataPing.Dist;
            end
            
            [~,p_min] = nanmin(abs(xdata-nanmin(echo_obj.echo_surf.XData(:))));
            [~,p_max] = nanmin(abs(xdata-nanmax(echo_obj.echo_surf.XData(:))));
            ping_range = p_min:p_max;
            switch echo_obj.echo_usrdata.geometry_y
                case 'samples'
                    ydata = trans_obj.get_transceiver_samples();
                case 'depth'
                    ydata=trans_obj.get_transceiver_depth([],[]);
                case 'range'
                    ydata=trans_obj.get_transceiver_range();
            end
            
            [~,s_min] = nanmin(abs(ydata-nanmin(echo_obj.echo_surf.YData(:))));
            [~,s_max] = nanmin(abs(ydata-nanmax(echo_obj.echo_surf.YData(:))));
            
            sample_range = s_min:s_max;
        end
        
        
        function ping_range = get_ping_range(echo_obj,trans_obj)
            
            switch echo_obj.echo_usrdata.geometry_x
                case 'pings'
                    xdata=trans_obj.get_transceiver_pings();
                case 'seconds'
                    xdata=trans_obj.get_transceiver_time();
                case 'meters'
                    xdata=trans_obj.GPSDataPing.Dist;
            end
            
            [~,p_min] = nanmin(abs(xdata-nanmin(echo_obj.echo_surf.XData(:))));
            [~,p_max] = nanmin(abs(xdata-nanmax(echo_obj.echo_surf.XData(:))));
            ping_range = p_min:p_max;
        end
        
        
        function sample_range = get_sample_range(echo_obj,trans_obj)
                

            switch echo_obj.echo_usrdata.geometry_y
                case 'samples'
                    ydata = trans_obj.get_transceiver_samples();
                case 'depth'
                    ydata=trans_obj.get_transceiver_depth([],[]);
                case 'range'
                    ydata=trans_obj.get_transceiver_range();
            end
            
            [~,s_min] = nanmin(abs(ydata-nanmin(echo_obj.echo_surf.YData(:))));
            [~,s_max] = nanmin(abs(ydata-nanmax(echo_obj.echo_surf.YData(:))));
            
            sample_range = s_min:s_max;
        end
        
        
        function display_echo_bottom(obj,trans_obj,varargin)
            
            p = inputParser;
            addRequired(p,'obj',@(x) isa(x,'echo_disp_cl'));
            addRequired(p,'trans_obj',@(x) isa(x,'transceiver_cl'));
            addParameter(p,'col_bot','',@(x) isnumeric(x)||ischar(x));
            addParameter(p,'curr_disp',curr_state_disp_cl(),@(x) isa(x,'curr_state_disp_cl'));
            
            parse(p,obj,trans_obj,varargin{:});
            
            curr_disp = p.Results.curr_disp;
            
            col_bot  =p.Results.col_bot;
            
            if isempty(col_bot)
                
                [cmap,col_ax,col_lab,col_grid,col_bot,col_txt,col_tracks]=init_cmap(curr_disp.Cmap);
                
            end
            
            idx_pings = obj.get_ping_range(trans_obj);
            
            
            if ~isempty(trans_obj.Bottom.Sample_idx)
                idx_bottom=trans_obj.Bottom.Sample_idx(idx_pings);
                xdata=trans_obj.get_transceiver_pings(idx_pings);
                ydata=trans_obj.get_transceiver_samples();
            else
                idx_bottom=[];
                xdata=[];
                ydata=[];
            end
            bt_h=obj.bottom_line_plot;
            if~isempty(idx_bottom)&&~isempty(xdata)&&~isempty(ydata)
                x=linspace(xdata(1),xdata(end),length(xdata));
                
                
                switch obj.echo_usrdata.geometry_y
                    case 'samples'
                        di=-1/2;
                        ydata=trans_obj.get_transceiver_samples()+di;
                        y=nan(size(x));
                        y(~isnan(idx_bottom))=ydata(idx_bottom(~isnan(idx_bottom)));
                        y((y-di)==numel(ydata))=nan;
                    case 'depth'
                        y=trans_obj.get_bottom_depth(idx_pings);
                    case 'range'
                        y=trans_obj.get_bottom_range(idx_pings);
                end
                
                
                
                set(bt_h,'XData',x,'YData',y,'visible',curr_disp.DispBottom,'color',col_bot);
                
            else
                set(bt_h,'XData',nan,'YData',nan,'visible',curr_disp.DispBottom,'color',col_bot);
            end
            
        end
        
        function [pos_m,pos_v,pos_h,pos_cb] = get_axes_position(obj,vpos_r,hpos_r)
            pos_m=obj.pos_in_parent;
            
            if isempty(obj.hori_ax)||strcmpi(obj.hori_ax.Visible,'off')
                hpos_r = 0;
            end
            
            if isempty(obj.vert_ax)||strcmpi(obj.vert_ax.Visible,'off')
                vpos_r = 0;
            end
            
              
            pos_v=[pos_m(1)-vpos_r*pos_m(3) pos_m(2) vpos_r*pos_m(3) pos_m(4)];            
            pos_h=[pos_m(1) pos_m(2)+pos_m(4) pos_m(3) hpos_r*pos_m(4)];
            
            if (isempty(obj.colorbar_h)||strcmpi(obj.colorbar_h.Visible,'off'))
                pos_cb=[pos_m(1)+pos_m(3) 0 0 pos_m(4)];
            else
                pos_cb=[pos_m(1)+pos_m(3)-0.05*pos_m(3) 0 0.05*pos_m(3) pos_m(4)];
            end
            
            pos_h=pos_h+[0 0 -pos_cb(3) 0];
            pos_m=pos_m+[0 0 -pos_cb(3) 0];
                        
            pos_h=pos_h+[0 -pos_h(4) 0 0];
            pos_v=pos_v+[0 0 0 -pos_h(4)];
            pos_m=pos_m+[0 0 0 -pos_h(4)];
            
            pos_v=pos_v+[pos_v(3) 0 0 0];
            pos_h=pos_h+[pos_v(3) 0 -pos_v(3) 0];
            pos_m=pos_m+[pos_v(3) 0 -pos_v(3) 0];
            
            width_colorbar=pos_cb(3);
            pos_cb(3)=width_colorbar*1/3;
            pos_cb(1)=pos_cb(1)+width_colorbar*1/3;
            height_col=pos_cb(4);
            pos_cb(2)=height_col*0.05;
            pos_cb(4)=height_col*0.9;
            
                     
            if ~isempty(obj.vert_ax)
                switch obj.vert_ax.YAxisLocation
                    case 'left'
                     pos_m = pos_m -[pos_v(3) 0 0 0];
                     pos_v = pos_v + [pos_m(3) 0 0 0];
                     pos_h(1) = pos_m(1);
                end
            end
            
            if ~isempty(obj.hori_ax)
                switch obj.hori_ax.XAxisLocation
                    case 'top'
                        pos_m = pos_m +[0 pos_h(4) 0 0];
                        pos_h = pos_h - [0 pos_m(4) 0  0];
                        pos_v(2) = pos_m(2);
                end
            end
            
        end
        
        function delete(obj)
           delete(obj.main_ax);
           delete(obj.vert_ax);
           delete(obj.hori_ax);
           delete(obj.colorbar_h);
           if ~isdeployed
               c = class(obj);
               disp(['ML object destructor called for class ',c]);
           end
        end
        
        function  set_axes_position(obj,vpos_r,hpos_r)
            [pos_m,pos_v,pos_h,pos_cb] = get_axes_position(obj,vpos_r,hpos_r);
            
            if ~isempty(obj.main_ax)
                set(obj.main_ax,'Position',pos_m);
            end
            
            if ~isempty(obj.colorbar_h)
                set(obj.colorbar_h,'Position',pos_cb);
            end   
            if ~isempty(obj.vert_ax)
                set(obj.vert_ax,'Position',pos_v);
            end
            if ~isempty(obj.hori_ax)
                set(obj.hori_ax,'Position',pos_h);
            end
        end
        
    end
end

