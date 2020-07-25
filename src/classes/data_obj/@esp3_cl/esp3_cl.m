classdef esp3_cl < handle
    
    properties
        main_figure        = [];
        layers             = layer_cl.empty();
        current_layer_id   = '';
        app_path           = app_path_create();
        process            = process_cl.empty();
        curr_disp          = curr_state_disp_cl();
        echo_disp_obj      = echo_disp_cl.empty();     

%         progress_bar_obj    = progress_bar_panel_cl.empty();
%         opt_figure         = [];
%         main_figure        = [];
%         sec_figure         = [];

%currently in main_figure appdata
%         iptPointerManager: [1×1 struct]
%            SelectArea: [1×1 struct]
%       ExternalFigures: [1×0 Figure]
%           Loading_bar: [1×1 struct]
%            Info_panel: [1×1 struct]
%        echo_tab_panel: [1×1 TabGroup]
%      option_tab_panel: [1×1 TabGroup]
%        algo_tab_panel: [1×1 TabGroup]
%             main_menu: [1×1 struct]
%              esp3_tab: [1×1 struct]
%              file_tab: [1×1 struct]
%           EchoInt_tab: [1×1 struct]
%        Secondary_freq: [1×1 struct]
%      Cursor_mode_tool: [1×1 struct]
%           Display_tab: [1×1 struct]
%             Lines_tab: [1×1 struct]
%       Calibration_tab: [1×1 struct]
%               Env_tab: [1×1 struct]
%        Processing_tab: [1×1 struct]
%        Layer_tree_tab: [1×1 struct]
%           Reglist_tab: [1×1 struct]
%               Map_tab: [1×1 struct]
%             ST_Tracks: [1×1 struct]
%                  sv_f: [1×1 struct]
%                  ts_f: [1×1 struct]
%           Algo_panels: [1×11 algo_panel_cl]
%           Denoise_tab: [1×1 struct]
%        multi_freq_tab: [1×1 struct]
%       interactions_id: [1×1 struct]
%            javaWindow: [1×1 com.mathworks.hg.peer.FigureFrameProxy$FigureFrame]
%                Dndobj: [1×1 dndcontrol]
%            ListenersH: [1×25 event.proplistener]
%            Axes_panel: [1×1 struct]
%             Mini_axes: [1×1 struct]
%           LinkedProps: [1×1 struct]
    end
    
    methods
        function obj = esp3_cl(varargin)
            try
                
                main_path = whereisEcho();
                main_figure_userData.logFile=fullfile(fullfile(main_path,'logs',[datestr(now,'yyyymmddHHMMSS') '_esp3.log']));
                
                %% Create log folder and start logger
                try
                    if ~isfolder(fullfile(main_path,'logs'))
                        mkdir(fullfile(main_path,'logs'));
                        disp('Log Folder Created')
                    end
                    diary(main_figure_userData.logFile);
                    disp(datestr(now));
                catch
                    disp('Could not start log...');
                end
                
                %% Checking and parsing input variables
                p = inputParser;
                addParameter(p,'nb_esp3_instances',0,@isnumeric);
                addParameter(p,'files_to_load',{},@iscell);
                addParameter(p,'scripts_to_run',{},@iscell);
                addParameter(p,'nodisplay',false,@islogical);
                addParameter(p,'online',true,@islogical);
                addParameter(p,'SaveEcho',0,@isnumeric);
                parse(p,varargin{:});
                
                nb_esp3_instances=p.Results.nb_esp3_instances;
                
                if ~isdeployed()&&isappdata(groot,'esp3_obj')
                    old_obj = getappdata(groot,'esp3_obj');
                    if ~isempty(old_obj.main_figure)&&ishandle(old_obj.main_figure)
                        delete(old_obj.main_figure);
                    end
                end
                
                setappdata(groot,'esp3_obj',obj);
                
                if ~p.Results.nodisplay
                    %% Get monitor's dimensions
                    [size_fig,units]=get_init_fig_size([]);
                    %% Defining the app's main window
                    obj.main_figure = new_echo_figure([],...
                        'Units',units,...
                        'Position',size_fig,... 
                        'Name','ESP3',...
                        'Tag','ESP3',...
                        'Resize','on',...
                        'MenuBar','none',...
                        'Toolbar','none',...
                        'Visible','off',...
                        'CloseRequestFcn',@closefcn_clean);
                    obj.main_figure.ResizeFcn = @resize_echo;
                    obj.main_figure.Interruptible = 'off';
                    obj.main_figure.BusyAction='cancel';
                    
                end
                
                %% Software version
                online=new_version_figure(obj.main_figure);
                
                %% Check if GPU computation is available %%
                [gpu_comp,~]=get_gpu_comp_stat();
                if gpu_comp
                    disp_perso(obj.main_figure,'GPU computation Available');
                    disp('GPU computation Available');
                else
                    disp_perso(obj.main_figure,'GPU computation Unavailable');
                    disp('GPU computation Unavailable');
                end
                
                %% Read ESP3 config file
                [obj.app_path,obj.curr_disp,~,~] = load_config_from_xml(1,1,1);
                obj.curr_disp.Online=online;
                
                if ~p.Results.nodisplay
                    disp_perso(obj.main_figure,'Listing available basemaps');
                    [basemap_list,~,~,~]=list_basemaps(1,obj.curr_disp.Online);
                    obj.curr_disp.Basemaps=basemap_list;
                    if ~ismember(obj.curr_disp.Basemap,basemap_list)
                        obj.curr_disp.Basemap='darkwater';
                    end
                end
                
                %% Create temporary data folder
                try
                    if ~isfolder(obj.app_path.data_temp.Path_to_folder)
                        mkdir(obj.app_path.data_temp.Path_to_folder);
                        disp_perso(obj.main_figure,'Data Temp Folder Created')
                        disp_perso(obj.main_figure,obj.app_path.data_temp.Path_to_folder)
                    end
                catch
                    disp_perso(obj.main_figure,'Creating new config_path.xml file with standard path and options')
                    [~,path_config_file,~]=get_config_files();
                    delete(path_config_file);
                    [obj.app_path,~,~,~] = load_config_from_xml(1,0,0);
                end
                
                %% Managing existing files in temporary data folder
                if ~p.Results.nodisplay
                    if nb_esp3_instances==1
                        files_in_temp=dir(fullfile(obj.app_path.data_temp.Path_to_folder,'*.bin'));
                        idx_old=1:numel(files_in_temp);%check all temp files...
                        if ~isempty(idx_old)
                            
                            % by default, don't delete
                            delete_files=0;
                            
                            choice=question_dialog_fig(obj.main_figure,'Delete files?','There are files in your ESP3 temp folder, do you want to delete them?','timeout',10,'default_answer',2);
                            
                            switch choice
                                case 'Yes'
                                    delete_files = 1;
                                case 'No'
                                    delete_files = 0;
                            end
                            
                            if isempty(choice)
                                delete_files = 0;
                            end
                            
                            if delete_files == 1
                                for i = 1:numel(idx_old)
                                    if exist(fullfile(obj.app_path.data_temp.Path_to_folder,files_in_temp(idx_old(i)).name),'file') == 2
                                        delete(fullfile(obj.app_path.data_temp.Path_to_folder,files_in_temp(idx_old(i)).name));
                                    end
                                end
                            end
                        end
                    end
                    
                    select_area.patch_h=[];
                    select_area.uictxt_menu_h=[];
                    setappdata(obj.main_figure,'SelectArea',select_area);
                    
                    setappdata(obj.main_figure,'ExternalFigures',matlab.ui.Figure.empty());
                    
                    obj.main_figure.Alphamap=obj.get_alphamap();
                    
                    %% Initialize the display and the interactions with the user
                    initialize_display(obj);
                    initialize_interactions_v2(obj.main_figure);
                    drawnow;
                    init_java_fcn(obj.main_figure);
                    update_cursor_tool(obj.main_figure);
                    init_listeners(obj);
                                      
                    obj.main_figure.UserData = main_figure_userData;
                    obj.main_figure.UserData.timer=[];
                end
                
                %% If files were loaded in input, load them now
                if ~isempty(p.Results.files_to_load)                 
                    obj.open_file(p.Results.files_to_load);
                end
                
                if ~isempty(p.Results.scripts_to_run)
                    obj.run_scripts(p.Results.scripts_to_run,'discard_loaded_layers',p.Results.SaveEcho==0,'update_display_at_loading',0) ;
                end
                
                if p.Results.SaveEcho>0
                    layers = obj.layers;
                    for uil = 1:numel(layers)
                        filepath=fileparts(layers(uil).Filename{1});
                        obj.curr_disp.update_curr_disp(filepath);
                        obj.set_layer(layers(uil));
                        for uic = 1:numel(layers(uil).ChannelID)
                            save_echo('vis','off','cid',layers(uil).ChannelID{uic});
                        end
                    end
                    cleanup_echo(obj.main_figure);
                end
                
            catch err
                warndlg_perso([],'Fatal Error','Failed to start ESP3');
                delete(obj.main_figure);
                if ~isdeployed
                    rethrow(err);
                end
            end           
        end
        
        function Alphamap = get_alphamap(obj)
            
            switch obj.curr_disp.DispBadTrans
                case 'off'
                    alpha_bt=0;
                case 'on'
                    alpha_bt=0.8;
            end
            
            switch obj.curr_disp.DispReg
                case 'off'
                    alpha_reg=0;
                case 'on'
                    alpha_reg=0.4;
            end
            
            switch obj.curr_disp.DispSpikes
                case 'off'
                    alpha_spikes=0;
                case 'on'
                    alpha_spikes=1;
            end
            
            Alphamap=[0 (1-obj.curr_disp.UnderBotTransparency/100) alpha_bt alpha_reg alpha_spikes 1];
            
        end
        
        function set.layers(obj,layers)
            obj.layers=layers;
            obj.layers(~isvalid(obj.layers))=[];
        end
        
        function add_echo_disp_obj(obj,echo_disp_obj_vec)
            for ui = 1:numel(echo_disp_obj_vec)
                edisp_obj = echo_disp_obj_vec(ui);
                if ~isempty(obj.echo_disp_obj)
                    tags = {obj.echo_disp_obj(:).Tag};
                    idx = strfind(edisp_obj.Tag,tags);
                    if isempty(idx)
                        obj.echo_disp_obj = [obj.echo_disp_obj edisp_obj];
                    else
                        delete(obj.echo_disp_obj);
                        obj.echo_disp_obj(idx) = edisp_obj;
                    end
                else
                    obj.echo_disp_obj = edisp_obj;
                end
            end
        end
        
        
        function delete(obj)
            
            if ~isdeployed
                c = class(obj);
                disp(['ML object destructor called for class ',c]);
            end
            
            nb_l=length(obj.layers);
            while nb_l>=1
                str_cell=list_layers(obj.layers(nb_l),'nb_char',80);
                try
                    fprintf('Deleting temp files from %s\n',str_cell{1});
                    obj.layers.delete_layers(obj.layers(nb_l).Unique_ID);
                catch
                    fprintf('Could not clean files from %s\n',str_cell{1});
                end
                nb_l=nb_l-1;
            end
            if ~isempty(obj.main_figure)&&ishandle(obj.main_figure)
                dndobj=getappdata(obj.main_figure,'Dndobj');
                delete(dndobj);
      
                appdata = get(obj.main_figure,'ApplicationData');
                fns = fieldnames(appdata);
                
                for ii = 1:numel(fns)
                    rmappdata(obj.main_figure,fns{ii});
                end
                delete(obj.main_figure);
            end
            
            if isappdata(groot,'esp3_obj')
                rmappdata(groot,'esp3_obj');
            end
               
        end
        
        function [lay,lay_idx]=get_layer(obj)
            lay_idx=find(strcmpi({obj.layers(:).Unique_ID},obj.current_layer_id));
            if ~isempty(lay_idx)
                lay=obj.layers(lay_idx);
            elseif ~isempty(obj.layers)
                lay_idx=1;
                lay=obj.layers(1);
                obj.current_layer_id=obj.layers(1).Unique_ID;
            else
                lay=layer_cl.empty();
            end
        end
        
        function set_layer(obj,lay_obj)
            if ~isempty({obj.layers(:).Unique_ID})
                if ismember(lay_obj.Unique_ID,{obj.layers(:).Unique_ID})
                    obj.current_layer_id=lay_obj.Unique_ID;
                end
            end
        end
        
    end
end
