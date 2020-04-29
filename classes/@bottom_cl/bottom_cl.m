classdef bottom_cl
    
    properties (Access = public, Constant = true)
        % IMPORTANT: This value is the format of this class. Update this
        % value if you modify or add the properties of this class
        Fmt_Version = '0.3';
    end
    
    properties
        
        Origin = '';     % Origin of this bottom (XML, or algorithm, etc.)
        Sample_idx = []; % Sample corresponding to bottom (int)
        Tag = [];        % 0 if bad ping, 1 if good ping
        
        % Roxann E1 "hardness" bottom parameter (energy of the tail of the
        % first echo), and Roxann E2 "roughness" bottom parameter (total
        % energy of the second echo) 
        E1 = [];      
        E2 = [];
        
        % Version of the bottom: -1 is copy from the current XML file
        % (default), 0 is latest version in database file, any n>0 is
        % closest version to version n from database.
        Version = []; 
        
    end

    
    methods
        
        %% constructor %%
        function obj = bottom_cl(varargin)
            
            % object gets constructed with default class values set above.
            % This section is to overwrite these values if provided in
            % input.
            
            % input parser
            % default values are that of class
            % NOTE: can't overwrite class version Fmt_Version
            p = inputParser;
            addParameter(p,'Origin',    obj.Origin,     @ischar);
            addParameter(p,'Sample_idx',obj.Sample_idx, @isnumeric);
            addParameter(p,'Tag',       obj.Tag,        @(x) isnumeric(x)||islogical(x));
            addParameter(p,'E1',        obj.E1,         @isnumeric);
            addParameter(p,'E2',        obj.E2,         @isnumeric);
            addParameter(p,'Version',   obj.Version,    @isnumeric);
            parse(p,varargin{:});
            
            % overwrite object properties with input values
            props = fieldnames(p.Results);
            for i = 1:length(props)
                obj.(props{i}) = p.Results.(props{i});
            end
            
            if ~isempty(obj.Sample_idx)
                if isempty(obj.Tag)
                    obj.Tag = ones(size(obj.Sample_idx)); % all good pings
                end
                if isempty(obj.E1)
                    obj.E1 = -999.*ones(size(obj.Sample_idx)); % undefined
                end
                if isempty(obj.E2)
                    obj.E2 = -999.*ones(size(obj.Sample_idx)); % undefined
                end
            end
            
        end
        
        %%
        function bot_out = concatenate_Bottom(bot_1,bot_2)
            
            % in case any of the two are empty, simply output the other
            if isempty(bot_1)
                bot_out = bot_2;
                return;
            elseif isempty(bot_2)
                bot_out = bot_1;
                return;
            end
            
            % otherwise, generate a new bottom
            if strcmp(bot_1.Origin,bot_2.Origin)
                bot_out = bottom_cl('Origin',bot_1.Origin);
            else
                bot_out = bottom_cl('Origin',['Concatenated ' bot_1.Origin ' and ' bot_2.Origin]);
            end
            
            % and in it, concatenate all concatenable fields
            props = fieldnames(bot_1);
            for i = 1:length(props)
                if ~any(strcmp(props{i}, {'Origin','Fmt_Version','Version'}))
                    bot_out.(props{i}) = [reshape(bot_1.(props{i}),1,[]), reshape(bot_2.(props{i}),1,[])];
                end
            end
           
            
        end

        %%
        function bottom_section = get_bottom_idx_section(bottom_obj,idx)
            
            % create new bottom section
            bottom_section = bottom_cl('Origin',bottom_obj.Origin,'Version',bottom_obj.Version);
            
            % save subset of data from original bottom into bottom section
            props = fieldnames(bottom_obj);
            for i = 1:length(props)
                if ~any(strcmp(props{i}, {'Origin','Fmt_Version','Version'}))
                    bottom_section.(props{i}) = bottom_obj.(props{i})(idx);
                end
            end
            
        end
        
        %%
        function Sample_idx = get.Sample_idx(bot_obj)
            
            Sample_idx = bot_obj.Sample_idx(:)';
            
        end
        
        %%
        function delete(obj)
            
            c = class(obj);
            if ~isdeployed
                disp(['ML object destructor called for class ',c])
            end
            
        end
        
    end
end

