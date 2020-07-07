classdef algo_param_cl < matlab.mixin.Copyable
    
    properties 
       Name = ''
       Value= 0
       Validation_fcn = @isnumeric
       Default_value= 0
       Value_range = [-inf inf]
       Disp_name = ''
       Tooltipstring = ''
       Precision = '%.2f'  
       Units = ''
    end
    
    methods
        function  obj=algo_param_cl(varargin)
            p = inputParser;
            addParameter(p,'Name', '', @ischar);
            addParameter(p,'Value', 0);
            addParameter(p,'Validation_fcn', 0);
            addParameter(p,'Default_value', 0);
            addParameter(p,'Value_range', [-inf inf]);
            addParameter(p,'Disp_name', '', @ischar);
            addParameter(p,'Tooltipstring', '', @ischar);
            addParameter(p,'Precision', '', @ischar);
            addParameter(p,'Units', '', @ischar);

            parse(p,varargin{:});
            results = p.Results;
            props = fieldnames(results);
            
            for i = 1:length(props)
                obj.(props{i}) = results.(props{i});
            end
        end
        
        function name=get_name(obj)
            name={obj(:).Name};
        end

        function cc=get_class(obj)
            cc=cell(1,numel(obj));
            for io=1:numel(obj)
                cc{io}=class(obj(io).Value_range);
            end
        end
        

        
        function str=to_string(obj)
            str=cell(1,numel(obj));
            for ui=1:numel(obj)
                if ~isempty(obj(ui).Units) && ~isempty(obj(ui).Disp_name)
                    str{ui}=sprintf('%s (%s)',obj(ui).Disp_name,obj(ui).Units);
                elseif ~isempty(obj(ui).Disp_name)
                    str{ui}=sprintf('%s',obj(ui).Disp_name);
                else
                    str{ui}='';
                end
            end
        end
        
        function set_value(obj,value)
            
            if ~isempty(value) && isnumeric(obj.Default_value)
                if obj.Validation_fcn(value) && value >= obj.Value_range(1) && value <= obj.Value_range(2)
                    obj.Value=value;
                else
                   if ~isdeployed()
                      fprintf('algo_param_cl: %s parameter (%s) not updated\n',obj.Name,obj.Disp_name);
                   end
                end
            else
                if obj.Validation_fcn(value)
                    obj.Value=value;
                elseif islogical(obj.Default_value) && isnumeric(value)
                    obj.Value=value>0;
                else
                    if ~isdeployed()
                        fprintf('algo_param_cl: %s parameter (%s) not updated\n',obj.Name,obj.Disp_name);
                    end
                end
            end 
        end
        
    end
    
end