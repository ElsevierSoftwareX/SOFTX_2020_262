
classdef algo_cl < matlab.mixin.Copyable
    properties
        Name
        Function
        Input_params
        Varargout
    end
    
    
    methods
        function obj = algo_cl(varargin)
            
            p = inputParser;
            
            addParameter(p,'Name','',@ischar);
            addParameter(p,'Input_params',[],@(x) isa(x,'algo_param_cl')||isempty(x));
            addParameter(p,'Varargin',[],@(x) isstruct(x)||isempty(x));
            addParameter(p,'Frequencies',[],@(x) isnumeric(x)||isempty(x));
            parse(p,varargin{:});
            
            results=p.Results;
            
            obj.Name=results.Name;
            
            obj.init_func();
            
            obj.init_input_params();
            
            if ~isempty(obj.Input_params)
                fields_in=obj.Input_params.get_name();
                for i=1:length(fields_in)
                    if isfield(results.Varargin,fields_in{i})
                        obj.set_input_param_value(fields_in{i},results.Varargin.(fields_in{i}));
                    end
                end
            end
            
            obj.Varargout=init_varargout(obj.Name);
            
        end
        
        function algo_obj_cp=copy_algo(algo_obj)
            algo_obj_cp=copy(algo_obj);
            
            for ipi = 1:numel(algo_obj.Input_params)
                algo_obj_cp.Input_params(ipi)=copy(algo_obj.Input_params(ipi));
            end
            
        end
        
        function input_struct=input_params_to_struct(obj)
            input_struct=[];
           for ui=1:numel(obj.Input_params) 
               input_struct.(obj.Input_params(ui).Name)=obj.Input_params(ui).Value;
           end
        end
        
        function set_input_param_value(obj,input_param_name,value)
            if ~isempty(obj.Input_params)
                names=obj.Input_params.get_name();
                idx_name=find(strcmpi(input_param_name,names));
                if ~isempty(idx_name)
                    obj.Input_params(idx_name).set_value(value);
                end
            end
        end
        
        function algo_param_obj = get_algo_param(obj,name)
           names = obj.Input_params.get_name();
           idx=strcmpi(names,name);
           if ~isempty(idx)
               algo_param_obj=obj.Input_params(idx);
           else
               algo_param_obj=[];
           end
        end
        
        function delete(obj)
            
%             if ~isdeployed
%                 c = class(obj);
%                 disp(['ML object destructor called for class ',c])
%             end
        end
        
        
    end
end

