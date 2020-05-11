classdef esp3_cl < handle
    
    properties
        main_figure        = [];
        layers             = layer_cl.empty();
        current_layer_id   = '';
        app_path           = app_path_create();
        process            = process_cl.empty();
        curr_disp          = curr_state_disp_cl();
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
                addParameter(p,'nodisplay',false,@islogical);
                addParameter(p,'online',true,@islogical);
                addParameter(p,'SaveEcho',0,@isnumeric);
                parse(p,varargin{:});
                
                nb_esp3_instances=p.Results.nb_esp3_instances;
                
                setappdata(groot,'esp3_obj',obj);
                
                if ~p.Results.nodisplay
                    %% Get monitor's dimensions
                    [size_fig,units]=get_init_fig_size([]);
                    %% Defining the app's main window
                    obj.main_figure = figure('Units',units,...
                        'Position',size_fig,... %Position and size normalized to the screen size ([left, bottom, width, height])
                        'DockControls','off',...
                        'Color','White',...
                        'Name','ESP3',...
                        'Tag','ESP3',...
                        'NumberTitle','off',...
                        'Resize','on',...
                        'MenuBar','none',...
                        'Toolbar','none',...
                        'visible','off',...
                        'WindowStyle','normal',...
                        'ResizeFcn',@resize_echo,...
                        'BusyAction','cancel',...
                        'Interruptible','off',...
                        'CloseRequestFcn',@closefcn_clean);
                    set(obj.main_figure,'BusyAction','cancel');
                    
                    %% Install mouse pointer manager in figure
                    iptPointerManager(obj.main_figure);
                    
                    %% Get Javaframe from Figure to set the Icon
                    javaFrame = get(obj.main_figure,'JavaFrame');
                    if ~isempty(javaFrame)
                        %             javaFrame.fHG2Client.setClientDockable(true);
                        %             set(javaFrame,'GroupName','ESP3');
                        javaFrame.setFigureIcon(javax.swing.ImageIcon(fullfile(whereisEcho(),'icons','echoanalysis.png')));
                    end
                end
                
                %% Software version
                online=new_version_figure(obj.main_figure);
                
                %% Check if GPU computation is available %%
                [gpu_comp,~]=get_gpu_comp_stat();
                if gpu_comp
                    disp_perso(obj.main_figure,'GPU computation Available');
                else
                    disp_perso(obj.main_figure,'GPU computation Unavailable');
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
                    
                    setappdata(obj.main_figure,'ExternalFigures',matlab.ui.Figure.empty())
                    switch obj.curr_disp.DispBadTrans
                        case 'off'
                            alpha_bt=0;
                        case 'on'
                            alpha_bt=0.7;
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
                    
                    obj.main_figure.Alphamap=[0 (1-obj.curr_disp.UnderBotTransparency/100) alpha_bt alpha_reg alpha_spikes 1];
                    
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
                    % If request was made to print display: print and close ESP3
                    
                    open_file([],[],p.Results.files_to_load,obj.main_figure);
                    
                    if p.Results.SaveEcho>0
                        save_echo(obj.main_figure,'','','main');
                        cleanup_echo(obj.main_figure);
                        delete(obj.main_figure);
                        return;
                    end
                end
                
                
            catch err
                warndlg_perso([],'Fatal Error','Failed to start ESP3');
                delete(obj.main_figure);
                if ~isdeployed
                    rethrow(err);
                end
            end
            
        end
        
        function set.layers(obj,layers)
            obj.layers=layers;
            obj.layers(~isvalid(obj.layers))=[];
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
            
            dndobj=getappdata(obj.main_figure,'Dndobj');
            delete(dndobj);
            
            appdata = get(obj.main_figure,'ApplicationData');
            fns = fieldnames(appdata);
            
            for ii = 1:numel(fns)
                rmappdata(obj.main_figure,fns{ii});
            end
            delete(obj.main_figure);
            
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
