classdef curr_state_disp_cl <handle
    
    properties (SetObservable = true)
        ChannelID='';
        Freq
        SecChannelIDs={};
        SecFreqs=[];
        AllChannels={};
        DispSecFreqs=1;
        DispSecFreqsWithOffset=1;
        DispSecFreqsOr='vert';
        Fieldname='sv';
        Fieldnames={'sv'};
        Type='Sv'
        Xaxes={'meters' 'pings' 'seconds'};
        Xaxes_current={'meters'};
        Cax     
        Caxes
        DispBottom='on';
        DispUnderBottom='off';
        UnderBotTransparency=90;
        DispBotHighVis
        DispTracks='on';
        DispBadTrans='on';
        DispSpikes='on';
        DispReg='on';
        DispLines='on';
        DispSurveyLines='on';
        CursorMode='Normal'
        Grid_x=[100 10 10];
        Grid_y=10;
        CurrLayerID='';
        GPU_computation=1;
        NbLayers=0;
        Cmap='ek60';
        Font='Nirmala UI';
        Bot_changed_flag=0;%flag=0 nothing change flag=1 : changes made nothing saved; flag=2  changes made saved to the xml file; flag=3  changes made saved to db file
        UIupdate=0;
        Online = 1;
        Basemap = 'World_Ocean_Base';
        Basemaps={};
        Move_dy_dx=[0.2 0.4];
        Disp_dy_dx=[1/4 1];
        Active_reg_ID={};
        Active_line_ID='';
        Reg_changed_flag=0; %flag=0 nothing change flag=1 : changes made nothing saved; flag=2  changes made saved to the xml file; flag=3  changes made saved to db file
        R_disp=[1 inf];
        V_axes_ratio=0.05;
        H_axes_ratio=0.15;
        EchoType='surface';
        EchoQuality='high';
    end
    
    methods
        function obj =curr_state_disp_cl(varargin)
            
            p = inputParser;
            addParameter(p,'Freq',38000,@isnumeric);
            addParameter(p,'Active_reg_ID',{},@iscell);       
            addParameter(p,'ChannelID','',@ischar);
            addParameter(p,'SecChannelIDs',{},@iscell);
            addParameter(p,'AllChannels',{},@iscell);
            addParameter(p,'SecFreqs',[],@isnumeric);
            addParameter(p,'DispSecFreqs',1,@isnumeric);
            addParameter(p,'DispSecFreqsWithOffset',1,@isnumeric);
            addParameter(p,'GPU_computation',1,@isnumeric);
            addParameter(p,'Fieldname','sv',@ischar);
            addParameter(p,'DispBottom','on',@ischar);          
            addParameter(p,'Basemap','landcover',@ischar);
            addParameter(p,'DispBotHighVis','off',@ischar);
            addParameter(p,'DispUnderBottom','on',@ischar);
            addParameter(p,'DispTracks','on',@ischar);
            addParameter(p,'DispSpikes','on',@ischar);
            addParameter(p,'DispBadTrans','on',@ischar);
            addParameter(p,'DispReg','on',@ischar);
            addParameter(p,'DispLines','on',@ischar);
            addParameter(p,'DispSurveyLines','on',@ischar);
            addParameter(p,'Xaxes',{'meters' 'pings' 'seconds'},@iscell);
            addParameter(p,'Xaxes_current','meters',@ischar);
            addParameter(p,'Grid_x',[100 10 10],@isnumeric);
            addParameter(p,'Grid_y',10,@isnumeric);
            addParameter(p,'Move_dy_dx',[0.2 .4],@isnumeric);
            addParameter(p,'Disp_dy_dx',[0.25 1],@isnumeric);
            addParameter(p,'CursorMode','Normal',@ischar);
            addParameter(p,'CurrLayerID','',@ischar);
            addParameter(p,'NbLayers',0,@isnumeric);
            addParameter(p,'Bot_changed_flag',0,@isnumeric);
            addParameter(p,'Reg_changed_flag',0,@isnumeric);
            addParameter(p,'Cmap','ek60',@ischar);
            addParameter(p,'Font','default',@ischar);
            addParameter(p,'UIupdate',0,@isnumeric);
            addParameter(p,'Online',1,@isnumeric);
            addParameter(p,'UnderBotTransparency',90,@isnumeric);
            addParameter(p,'V_axes_ratio',0.05,@isnumeric);
            addParameter(p,'H_axes_ratio',0.15,@isnumeric);
            addParameter(p,'EchoType','surface',@ischar);
            addParameter(p,'EchoQuality','high',@ischar);
            parse(p,varargin{:});
            results=p.Results;
            props=fieldnames(results);
            
            for i=1:length(props)
                obj.(props{i})=results.(props{i});
            end
            
            obj.Fieldnames={};
            obj.Caxes={};            
            obj.setTypeCax();
            
        end
    end
    
    methods
        
        function setActive_reg_ID(obj,ID)
           if~iscell(ID)
               ID={ID};
           end   
           ID=unique(ID);
           obj.Active_reg_ID=ID;
        end
        
        function [dx,dy]=get_dx_dy(obj)
            dy=obj.Grid_y;
            dx=obj.Grid_x(strcmp(obj.Xaxes_current,obj.Xaxes));
        end
        
        function set_dx_dy(obj,dx,dy,curr_axes)
            if ~isempty(dy)
                obj.Grid_y=dy;
            end
            if~isempty(curr_axes)
                obj.Xaxes_current=curr_axes;
            end
            if ~isempty(dx)
                obj.Grid_x(strcmp(obj.Xaxes_current,obj.Xaxes))=dx;
            end
        end
        
        function setCax(obj,cax)
            if cax(2)>cax(1)
                idx_field=find(cellfun(@(x) strcmpi(obj.Fieldname,x),obj.Fieldnames));
                
                if ~isempty(idx_field)
                    obj.Caxes{idx_field}=cax;
                    obj.Cax=cax;
                else
                    obj.Cax=cax;
                end
            end
        end
        
                
        function pointer=get_pointer(obj)
            %Choice of pointer being: ‘hand’, ‘hand1’, ‘hand2’, ‘closedhand’, ‘glass’, ‘glassplus’, ‘glassminus’, 
            %‘lrdrag’, ‘ldrag’, ‘rdrag’, ‘uddrag’, ‘udrag’, ‘ddrag’, ‘add’, ‘addzero’, ‘addpole’, ‘eraser’, 
            %‘help’, ‘modifiedfleur’, ‘datacursor’, ‘rotate’
            switch obj.CursorMode
                case 'Pan'
                    pointer='hand';
                case 'Zoom In'
                    pointer='glassplus';
                case 'Zoom Out'
                    pointer='glassminus';
                case 'Bad Transmits'
                    pointer='lrdrag';
                case 'Edit Bottom'
                    pointer='crosshair';
                case 'Add ST'
                    pointer='crosshair';
                case 'Measure'
                    pointer='datacursor';
                case 'Create Region'
                    pointer='cross';
                case 'Draw Line'
                    pointer='addpole';
                case 'Erase and fill Soundings'
                    pointer='eraser';
                case 'Normal'
                    pointer='arrow';
            end
        end
        
        function setTypeCax(obj)
            
            [cax,obj.Type,~]=init_cax(obj.Fieldname);
          
            idx_field=find(cellfun(@(x) strcmpi(obj.Fieldname,x),obj.Fieldnames));
            
            if ~isempty(idx_field)
                obj.Cax=obj.Caxes{idx_field};
            else
                obj.Caxes=[obj.Caxes cax];
                obj.Fieldnames=[obj.Fieldnames obj.Fieldname];
                obj.Cax=cax;
            end
        end
        
        function setType(obj)
            
            [~,obj.Type,~]=init_cax(obj.Fieldname);
            
            idx_field=find(cellfun(@(x) strcmpi(obj.Fieldname,x),obj.Fieldnames));
            
            if ~any(idx_field)
                obj.Fieldnames=[obj.Fieldnames obj.Fieldname];
            end
        end
        
        function setField(obj,field)
            [~,obj.Type,~]=init_cax(field);
            obj.Fieldname=field;
            obj.setTypeCax();
        end
        
        function cax=getCaxField(obj,field)
            idx_field=find(cellfun(@(x) strcmpi(field,x),obj.Fieldnames));
            if ~isempty(idx_field)
                cax=obj.Caxes{idx_field};
            else
                [cax,~,~]=init_cax(field);
            end
        end
        
        function delete(obj)
            
            if ~isdeployed
                c = class(obj);
                disp(['ML object destructor called for class ',c]);
            end
        end
        
    end
    
end

