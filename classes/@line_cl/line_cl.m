
classdef line_cl < handle
    properties
        Name=''
        ID=generate_Unique_ID([])
        Reference = 'Surface';
        Tag=''
        Type=''
        Range=[]
        Time=[]
        Data=[]
        UTC_diff=0
        Dist_diff=0
        File_origin
        Dr=0;
    end
    
    
    methods
        
        function obj= line_cl(varargin)
            
            p = inputParser;
            addParameter(p,'Name','Line',@ischar);
            addParameter(p,'ID',generate_Unique_ID([]),@ischar);
            addParameter(p,'Tag','',@ischar);
            addParameter(p,'Type','',@ischar);
            addParameter(p,'Range',[],@isnumeric);
            addParameter(p,'Data',[],@isnumeric);
            addParameter(p,'Time',[],@isnumeric);
            addParameter(p,'UTC_diff',0,@isnumeric);
            addParameter(p,'Dist_diff',0,@isnumeric);
            addParameter(p,'Reference','Surface',@ischar);
            addParameter(p,'File_origin',{''},@iscell);
            
            addParameter(p,'Dr',0,@isnumeric);
            parse(p,varargin{:});
            
            results=p.Results;
            props=fieldnames(results);
            
            for i=1:length(props)
                obj.(props{i})=results.(props{i});
            end
            if isempty(obj.Data)
                obj.Data=nan(size(obj.Range));
            end
        end
        
        function change_time(obj,dt)
            obj.Time=obj.Time+dt/24-obj.UTC_diff/24;
            obj.UTC_diff=dt;
        end
        
        function change_range(obj,dr)
            obj.Range=obj.Range+(dr-obj.Dr);
            obj.Dr=dr;
        end
        
        function line_copy=copy_line(line_obj)
            line_copy=line_cl(...
                'Name',line_obj.Name,...
                'ID',line_obj.ID,...
                'Tag',line_obj.Tag,...
                'Type',line_obj.Type,...
                'Range',line_obj.Range,...
                'Data',line_obj.Data,...
                'Time',line_obj.Time,...
                'UTC_diff',line_obj.UTC_diff,...
                'Dist_diff',line_obj.Dist_diff,...
                'File_origin',line_obj.File_origin,...
                'Dr',line_obj.Dr);
        end
        function str=print(obj)
            [~,f_temp,~]=cellfun(@fileparts,obj.File_origin,'un',0);
            f_temp=strjoin(f_temp,'\n');
            str=sprintf('%s %s\n%s',obj.Name,obj.Tag,f_temp);
        end
        
        function lines_cat=concatenate_lines(lines,merge_type)
            
            lines_cat=[];
            switch merge_type
                case 'ID'
                    types_all={lines(:).ID};
                case 'Tag'
                    types_all={lines(:).Tag};
                case 'Type'
                    types_all={lines(:).Type};
            end
            types=unique(types_all);
            
            for ij=1:numel(types)
                if isempty(types{ij})
                    line_tmp=lines(strcmp(types_all,types{ij}));
                else
                    lines_tmp=lines(strcmp(types_all,types{ij}));
                    r_out=[];
                    data_out=[];
                    time_out=[];
                    utc_diff=0;
                    
                    for i=1:numel(lines_tmp)
                        
                        idx_add=~isnan(lines_tmp(i).Range(:)');
                        time_new= lines_tmp(i).Time(idx_add);
                        
                        r_new=lines_tmp(i).Range(idx_add);
                        
                        if ~isempty(lines_tmp(i).Data)
                            data_new= lines_tmp(i).Data(idx_add);
                        else
                            data_new=nan(size(lines_tmp(i).Range(idx_add)));
                        end
                        if i>1
                            if lines_tmp(i).UTC_diff~=utc_diff
                                time_new=time_new-lines_tmp(i).UTC_diff+utc_diff;
                            end
                        else
                           utc_diff=lines_tmp(i).UTC_diff; 
                        end
                        time_out=[time_out time_new(:)'];
                        r_out=[r_out r_new(:)'];
                        data_out=[data_out data_new(:)'];
                    end
                    
                     %figure();plot(time_out,r_out)
                    [time_out,idx_sort]=unique(time_out);
                    data_out=data_out(idx_sort);
                    r_out=r_out(idx_sort);
                   %figure();plot(time_out,r_out)
                    
                    line_tmp=line_cl(...
                        'Name',lines_tmp(1).Name,...
                        'ID',lines_tmp(1).ID,...
                        'Tag',lines_tmp(1).Tag,...
                        'Type',lines_tmp(1).Type,...
                        'Range',r_out,...
                        'Data',data_out,...
                        'Time',time_out,...
                        'UTC_diff',utc_diff,...
                        'Dist_diff',lines_tmp(1).Dist_diff,...
                        'File_origin',lines_tmp(1).File_origin,...
                        'Dr',lines_tmp(1).Dr);
                end
                lines_cat=[lines_cat line_tmp];
            end
        end
        
        
        function line_section=get_line_time_section(line_obj,ts,te)
            line_section=line_obj.copy_line();
            idx_rem=line_obj.Time<ts|line_obj.Time>te;
            line_section.Time(idx_rem)=[];
            line_section.Range(idx_rem)=[];
            line_section.Data(idx_rem)=[];
        end
        
        
        function delete(obj)
            if ~isdeployed
                c = class(obj);
                disp(['ML object destructor called for class ',c])
            end
        end
        
        
    end
end
