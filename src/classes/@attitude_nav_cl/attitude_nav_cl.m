classdef attitude_nav_cl
    properties
        Heading = [];
        Heave = [];
        Pitch = [];
        Roll = [];
        Yaw = [];
        Time = [];
        NMEA_motion = '';
        NMEA_heading = '';
        %SOG
    end
    
    methods
        function obj = attitude_nav_cl(varargin)
            
            p = inputParser;
            
            addParameter(p,'Heading',[],@isnumeric);
            addParameter(p,'Roll',[],@isnumeric);
            addParameter(p,'Heave',[],@isnumeric);
            addParameter(p,'Pitch',[],@isnumeric);
            addParameter(p,'Yaw',[],@isnumeric);
            addParameter(p,'Time',[],@isnumeric);
            addParameter(p,'NMEA_heading','',@ischar);
            addParameter(p,'NMEA_motion','',@ischar);
            %addParameter(p,'SOG',[],@isnumeric);
            
            parse(p,varargin{:});
            
            if ~all([isempty(p.Results.Heading) isempty(p.Results.Roll) isempty(p.Results.Pitch) isempty(p.Results.Heave) isempty(p.Results.Yaw)])
                results=p.Results;
                props=fieldnames(results);
                props_obj=fieldnames(obj);
                
                for i=1:length(props)
                    if isprop(obj,props{i})
                        if isrow(results.(props{i}))||ismember(props{i},{'NMEA_heading' 'NMEA_motion'})
                            obj.(props{i})=results.(props{i});
                        else
                            obj.(props{i})=results.(props{i})';
                        end
                    end
                end
                
                [~,idx_sort]=sort(obj.Time);
                
                for i=1:length(props_obj)
                    if ~isempty(obj.(props_obj{i}))&&numel(obj.(props_obj{i}))==numel(idx_sort)
                        obj.(props_obj{i})=obj.(props_obj{i})(idx_sort);
                    else
                        switch props_obj{i}
                            case 'Heading'
                                obj.Heading=nan(size(obj.Time));
                            case {'NMEA_heading' 'NMEA_motion'}
                            otherwise
                                obj.(props_obj{i})=zeros(size(obj.Time));
                        end
                    end
                end
                
            else
                
                if isrow(p.Results.Time)
                    obj.Time=p.Results.Time;
                else
                    obj.Time=p.Results.Time';
                end
                ssp=size(obj.Time);
                obj.Heading=nan(ssp);
                obj.Roll=zeros(ssp);
                obj.Pitch=zeros(ssp);
                obj.Heave=zeros(ssp);
                obj.Yaw=zeros(ssp);
                
                %obj.SOG=zeros(nb_pings);
                
            end
            
            obj.Yaw(isnan(obj.Yaw))=0;
            obj.Roll(isnan(obj.Roll))=0;
            obj.Pitch(isnan(obj.Pitch))=0;
            obj.Heave(isnan(obj.Heave))=0;
            
        end
        
        %% export attitude data to .csv file
        function save_attitude_to_file(obj,fileN,idx_pings)
            
            if isempty(idx_pings)
                idx_pings = 1:length(obj.Time);
            end
            
            struct_obj.Heading = obj.Heading(idx_pings);
            struct_obj.Roll    = obj.Roll(idx_pings);
            struct_obj.Pitch   = obj.Pitch(idx_pings);
            struct_obj.Heave   = obj.Heave(idx_pings);
            struct_obj.Yaw     = obj.Yaw(idx_pings);
            struct_obj.Time    = cellfun(@(x) datestr(x,'dd/mm/yyyy HH:MM:SS'),(num2cell(obj.Time(idx_pings))),'UniformOutput',0);
            
            
            ff=fieldnames(struct_obj);
            
            for idi=1:numel(ff)
                if isrow(struct_obj.(ff{idi}))
                    struct_obj.(ff{idi})=struct_obj.(ff{idi})';
                end
            end
            
            struct2csv(struct_obj,fileN);
            
        end
        
        
        function attitude_out=concatenate_AttitudeNavPing(attitude_1,attitude_2)
            
             if isempty(attitude_1)
                attitude_out=attitude_2;
                return;
            end
            
            if isempty(attitude_2)
                attitude_out=attitude_1;
                return;
            end
            
            
            if ~isempty(attitude_1)&&~isempty(attitude_2)
                
                heading=[attitude_1.Heading attitude_2.Heading];
                roll=[attitude_1.Roll attitude_2.Roll];
                heave=[attitude_1.Heave attitude_2.Heave];
                pitch=[attitude_1.Pitch attitude_2.Pitch];
                yaw=[attitude_1.Yaw attitude_2.Yaw];
                time=[attitude_1.Time attitude_2.Time];
                
                
                attitude_out=attitude_nav_cl('Heading',heading,...
                    'Roll',roll,...
                    'Heave',heave,...
                    'Pitch',pitch,...
                    'Yaw',yaw,...
                    'Time',time,'NMEA_motion',attitude_1.NMEA_motion,'NMEA_heading',attitude_1.NMEA_heading);
            else
                attitude_out=attitude_nav_cl.empty();
            end
            
        end
        
        function att_nav_section=get_AttitudeNav_idx_section(att_nav_obj,idx)
            idx(idx<=0|idx>numel(att_nav_obj.Time))=[];
            att_nav_section=att_nav_obj;
            att_nav_section.Time=att_nav_obj.Time(idx);
            att_nav_section.Heading=att_nav_obj.Heading(idx);
            att_nav_section.Roll=att_nav_obj.Roll(idx);
            att_nav_section.Heave=att_nav_obj.Heave(idx);
            att_nav_section.Pitch=att_nav_obj.Pitch(idx);
            att_nav_section.Yaw=att_nav_obj.Yaw(idx);
        end
        
    end
    
    methods(Static)
        
        
        function obj=load_att_from_file(fileN)
            if ~iscell(fileN)
                fileN={fileN};
            end
            
            for ifi=1:length(fileN)
                fprintf('Importing attitude from file %s\n',fileN{ifi});
                try

                    opts = detectImportOptions(fileN{ifi});
                    temp=readtable(fileN{ifi},opts);
                    
                    fields =ismember({'Heading','Roll','Heave','Pitch','Yaw','Time'},temp.Properties.VariableNames);
                    %% SECTION TITLE
                    % DESCRIPTIVE TEXT
                    
                    if iscell(temp.Heading)
                        temp.Heading=nan(size(temp.Time));
                    end
                    
                    if all(fields)
                        idx_keep=~isnat(temp.Time);
                        obj_temp=attitude_nav_cl('Heave',temp.Heave(idx_keep),'Heading',temp.Heading(idx_keep),...
                            'Yaw',temp.Yaw(idx_keep),'Pitch',temp.Pitch(idx_keep),'Roll',temp.Roll(idx_keep),'Time',datenum(temp.Time(idx_keep)));
                    else
                        [pathf,filen,ext]=fileparts(fileN{ifi});
                        obj_temp=csv_to_attitude(pathf,[filen ext]);
                    end
                    
                catch
                    [pathf,filen,ext]=fileparts(fileN{ifi});
                    obj_temp=csv_to_attitude(pathf,[filen ext]);
                end
                fprintf('Attitude import finished\n');
                if ifi==1
                    obj=obj_temp;
                else
                    obj=concatenate_AttitudeNavPing(obj,obj_temp);
                end
                
            end
        end
        
        function delete(obj)
            
            if ~isdeployed
                c = class(obj);
                disp(['ML object destructor called for class ',c])
            end
        end
        
        
        
    end
    
end