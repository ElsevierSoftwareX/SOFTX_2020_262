classdef progress_bar_panel_cl < handle
    
    properties
        progpanel
        progaxes
        progaxes_txt
        progpatch
        progtext
        proglabel
        Minimum=0;
        Maximum=1;
        Value=0;
    end
    
    methods
        function obj = progress_bar_panel_cl(panel_parent)
            
            if isempty(panel_parent)
                fig=figure();
                panel_parent=uipanel(fig,'units','norm','position',[0 0 1 0.1]);
            end
            
            pos=[0 0 1 1];
            size_ax=[0.2 0.8];
            dx=0.01;
            
            obj.progaxes = axes( panel_parent,...
                'units','norm',...
                'Position', [dx (pos(4)-size_ax(2))/2 size_ax(1) size_ax(2)], ...
                'XLim', [0 1], ...
                'YLim', [0 1], ...
                'Box', 'on', ...
                'visible','off',...
                'ytick', [], ...
                'xtick', [],...
                'CLim',[0 1]);
            [cmap,col_ax,col_lab,col_grid,col_bot,col_txt,col_tracks]=init_cmap('GMT_ocean');%('beer-lager');
            colormap(obj.progaxes,cmap);
            obj.progaxes_txt = axes( panel_parent,...
                'units','norm',...
                'Position', [obj.progaxes.Position(3)+2*dx (pos(4)-size_ax(2))/2 pos(3)-obj.progaxes.Position(3)-3*dx size_ax(2)], ...
                'XLim', [0 1], ...
                'YLim', [0 1], ...
                'Box', 'off', ...
                'visible','off',...
                'ytick', [], ...
                'xtick', [],...
                'tag','progaxes_txt');
            
            obj.progpatch = patch( obj.progaxes,...
                'XData', [0 0 0 0], ...
                'visible','off',...
                'YData', [0 0 1 1],...
                'CData', [1 1 1 1],...
                'FaceAlpha',0.8,...
                'FaceColor','interp');
            
            obj.progtext = text(obj.progaxes,...
                0.5, 0.5, '0%', ...
                'HorizontalAlignment', 'Center', ...
                'VerticalAlignment','middle',...
                'visible','off',...
                'FontUnits', 'Normalized', ...
                'FontSize', 0.6 ,'Interpreter','none',...
                'tag','progtext');
            
            obj.proglabel = text(obj.progaxes_txt,...
                1, 0.5, '', ...
                'HorizontalAlignment', 'right', ...
                'VerticalAlignment','middle',...
                'FontUnits', 'Normalized', ...
                'visible','on',...
                'FontSize', 0.6,'Interpreter','none','tag','progtext' );
             update_progress_bar(obj);
        end
        
        function set(obj,varargin)
            if ~rem(numel(varargin),2)==0
                return;
            end
           
            for i=1:2:numel(varargin)
                obj.(varargin{i})=varargin{i+1};
            end
            update_progress_bar(obj);
        end
        

        function setVisible(obj,val)
            if val>0
                obj.progpatch.Visible='on';
                obj.progtext.Visible='on';
                obj.progaxes.Visible='on';
            else
                obj.progpatch.Visible='off';
                obj.progtext.Visible='off';
                obj.progaxes.Visible='off';
            end
            drawnow limitrate nocallbacks;
        end
        
        function  update_progress_bar(obj)  
            ratio=floor((obj.Value-obj.Minimum)/(obj.Maximum-obj.Minimum)*100);
            
            if ratio==round(obj.progpatch.XData(2)*100)
                return;
            end    

            obj.progpatch.XData=[0 ratio/100 ratio/100 0];
            obj.progpatch.CData=[1 1-ratio/100 1-ratio/100 1];
            str_disp=sprintf('%.0f%%',ratio);
            %disp(str_disp);
            obj.progtext.String=str_disp;

            pause(1e-9);
            
        end
        
        function setText(obj,str)
            obj.proglabel.String=str;            
            %drawnow limitrate nocallbacks;
            pause(1e-9);
            disp(str);
        end
        
    end
end

