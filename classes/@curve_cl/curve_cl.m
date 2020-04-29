
classdef curve_cl
    properties
        XData=[];
        YData=[];
        SD=[];
        Tag='';
        Xunit='';
        Yunit='';
        Name='';
        Type='';
        Unique_ID='';
    end
    
    
    methods
        function obj = curve_cl(varargin)
            p = inputParser;
                        
            addParameter(p,'XData',[],@isnumeric);
            addParameter(p,'YData',[],@isnumeric);
            addParameter(p,'SD',[],@isnumeric);
            addParameter(p,'Tag','',@ischar);
            addParameter(p,'Xunit','',@ischar);
            addParameter(p,'Yunit','',@ischar);
            addParameter(p,'Type','',@ischar);
            addParameter(p,'Name','',@ischar);
            addParameter(p,'Unique_ID',generate_Unique_ID([]),@ischar);
            
            parse(p,varargin{:});

            results=p.Results;
            props=fieldnames(results);
            
            for i=1:length(props)               
                obj.(props{i})=results.(props{i});            
            end    
            
            if isempty(obj.SD)
                obj.SD=nan(size(obj.XData));
            end

        end
                
        function delete(obj)
            
            if ~isdeployed
                c = class(obj);
                disp(['ML object destructor called for class ',c])
            end
        end
        
        function sucess=curve_to_csv(obj,fileN)
        sucess=0; 
 
        fid=fopen(fileN,'w+');
        
        if fid~=0
             for i_obj=1:numel(obj)
                 if i_obj==1
                    fprintf(fid,'%s,',obj(i_obj).Xunit);
                     fprintf(fid,'%.2f,' ,obj(i_obj).XData);
                     fprintf(fid,'\n');
                 end
                 fprintf(fid,'%s(%s),',obj(i_obj).Name,obj(i_obj).Yunit);
                 fprintf(fid,'%.2f,' ,obj(i_obj).YData);fprintf(fid,'\n');
                 fprintf(fid,'std %s(%s),',obj(i_obj).Name,obj(i_obj).Yunit);
                 fprintf(fid,'%.2f,' ,obj(i_obj).SD);fprintf(fid,'\n');
                 
             end
            fclose(fid);
            sucess=1;
        end
            
            
        end
    end
end


