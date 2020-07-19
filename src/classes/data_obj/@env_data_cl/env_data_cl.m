
classdef env_data_cl < matlab.mixin.Copyable
    properties
        Acidity=8;
        Depth=0;
        Salinity=35;
        SoundSpeed=1500
        Temperature=18
        SVP=struct('depth',[],'soundspeed',[],'ori','constant');
        CTD=struct('depth',[],'temperature',[],'salinity',[],'ori','constant');
        DropKeelOffset=0;
        DropKeelOffsetIsManual=0;
        Latitude=-45;
        SoundVelocityProfile=[]
        SoundVelocitySource='';
        WaterLevelDraft=0;
        WaterLevelDraftIsManual=0;
        TransducerName='';
    end
    methods
        function obj = env_data_cl(varargin)
            p = inputParser;
            
            addParameter(p,'Acidity',8,@isnumeric);
            addParameter(p,'Depth',100,@isnumeric);
            addParameter(p,'Salinity',35,@isnumeric);
            addParameter(p,'Temperature',18,@isnumeric);
            addParameter(p,'SoundSpeed',1490,@isnumeric)
            addParameter(p,'SVP',struct('depth',[],'soundspeed',[],'ori','constant'),@(x) isstruct(x)||ischar(x));
            addParameter(p,'CTD',struct('depth',[],'temperature',[],'salinity',[],'ori','constant'),@(x) isstruct(x)||ischar(x));
            parse(p,varargin{:});
            
            
            results=p.Results;
            props=fieldnames(results);
            
            for i=1:length(props)
                switch props{i}
                    
                    case 'SVP'
                        if isstruct(results.SVP)
                            obj.SVP=results.SVP;
                        else
                            obj.load_svp(results.SVP);
                        end
                    case 'CTD'
                        if isstruct(results.CTD)
                            obj.CTD=results.CTD;
                        else
                        obj.load_ctd(results.CTD);
                        end
                    otherwise
                        if isnumeric(results.(props{i}))
                            obj.(props{i})=double(results.(props{i}));
                        else
                            obj.(props{i})=(results.(props{i}));
                        end
                end
            end
            
  
            
        end
        function delete(obj)
            if ~isdeployed
                c = class(obj);
                disp(['ML object destructor called for class ',c])
            end
        end
        
        function new_obj=copy_env_data(obj)
            new_obj=env_data_cl();
            props=properties(obj);
            
            for i=1:length(props)
                new_obj.(props{i})=obj.(props{i});
            end
        end
        
        function  obj=set_svp(obj,depth,soundspeed,ori)
            obj.SVP.depth=double(depth(:));
            obj.SVP.soundspeed=double(soundspeed(:));
            
            if isempty(ori)
                ori=obj.SVP.ori;
            end
            
            if isempty(depth)&&strcmpi(char(ori),'profile')
                obj.SVP.ori='constant';
            else
                obj.SVP.ori=lower(char(ori));
            end
        end
        function  obj=set_ctd(obj,depth,temperature,salinity,ori)
            obj.CTD.depth=double(depth(:));
            obj.CTD.temperature=double(temperature(:));
            obj.CTD.salinity=double(salinity(:));
            
            if isempty(ori)
                ori=obj.CTD.ori;
            end
            
            if isempty(depth)&&strcmpi(char(ori),'profile')
                obj.CTD.ori='constant';
            else
                obj.CTD.ori=lower(char(ori));
            end
        end
        
        function env_data_obj=svp_from_ctd(env_data_obj)
            if ~isempty(env_data_obj.CTD.depth)
                c=seawater_svel_un95(env_data_obj.CTD.salinity,env_data_obj.CTD.temperature,env_data_obj.CTD.depth);
                env_data_obj.set_svp(env_data_obj.CTD.depth,c,'');
            end
        end
        
        function save_ctd(env_obj,fname)
            ctd=rmfield(env_obj.CTD,'ori');
            tab=struct2table(ctd);
            writetable(tab,fname,'Filetype','text','Delimiter',',');
            fprintf('CTD profile saved to %s\n',fname);
        end
        
        function save_svp(env_obj,fname)
            svp=rmfield(env_obj.SVP,'ori');
            tab=struct2table(svp);
            writetable(tab,fname,'Filetype','text','Delimiter',',');
            fprintf('SVP profile saved to %s\n',fname);
        end
        
        function load_svp(env_obj,fname)
            
            if isfile(fname)
                try
                    opts = detectImportOptions(fname,'FileType','text');
                    tab=readtable(fname,opts);
                    tabs=table2struct(tab,'ToScalar',true);
                     fprintf('Loaded SVP profile from %s.\n',fname);
                    if all(isfield(tabs,{'soundspeed','depth'}))&&~isempty(tabs.depth)
                        env_obj.set_svp(tabs.depth,tabs.soundspeed,'profile');
                    end
                catch err
                    fprintf('Could not load SVP file %s. Using constant value\n',fname);
                    print_errors_and_warnings([],'error',err);
                    env_obj.SVP.ori='constant';
                end
            else
                switch fname
                    case {'constant' 'theoritical' 'profile'}
                        env_obj.SVP.ori=fname;
                    otherwise
                        env_obj.SVP.ori='constant';
                end
            end
        end
        
        function load_ctd(env_obj,fname)
            
            if isfile(fname)
                try
                    opts = detectImportOptions(fname,'FileType','text');
                    tab=readtable(fname,opts);
                    tabs=table2struct(tab,'ToScalar',true);
                     fprintf('Loaded CTD file from %s.\n',fname);
                    if all(isfield(tabs,{'temperature','salinity','depth'}))&&~isempty(tabs.depth)
                        env_obj.set_ctd(tabs.depth,tabs.temperature,tabs.salinity,'profile');
                    end
                catch err
                    fprintf('Could not load CTD profile %s. Using constant value',fname);
                    print_errors_and_warnings([],'error',err);
                    env_obj.CTD.ori='constant';
                end
            else
                switch fname
                    case {'constant' 'theoritical' 'profile'}
                        env_obj.CTD.ori=fname;
                    otherwise
                        env_obj.CTD.ori='constant';
                end
            end
        end
    end
end