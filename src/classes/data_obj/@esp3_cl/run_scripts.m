
function surv_objs_out = run_scripts(esp3_obj,script_files,varargin)

%% Managing input variables
app_path        = esp3_obj.app_path;
layers_out      = esp3_obj.layers;
gui_main_handle = esp3_obj.main_figure;

cvs_root        = app_path.cvs_root.Path_to_folder;
data_root       = app_path.data_root.Path_to_folder;
PathToMemmap    = app_path.data_temp.Path_to_folder;

% input parser
p = inputParser;


addRequired(p,'esp3_obj',@(x) isa(x,'esp3_cl')); % script file(s)
addRequired(p,'script_files',@(x) ischar(x)|iscell(x)); % script file(s)
addParameter(p,'origin','xml',@(x) ismember(x,{'xml','mbs'})); % script type "xml" or "mbs"
addParameter(p,'PathToResults',app_path.results.Path_to_folder,@ischar);
addParameter(p,'tag','raw',@(x) ischar(x));
addParameter(p,'discard_loaded_layers',false,@islogical);
addParameter(p,'update_display_at_loading',ispc(),@(x) isnumeric(x)||islogical(x));

% parse
parse(p,esp3_obj,script_files,varargin{:});
% get results

origin          = p.Results.origin;
tag             = p.Results.tag;

PathToResults    = p.Results.PathToResults;


%% processing

surv_objs_out=[];
% check script filenames
if ~iscell(script_files)
    script_files = {script_files};
end

% % disable windows temporarily
% enabled_obj = findobj(gui_main_handle,'Enable','on');
% set(enabled_obj,'Enable','off');
% drawnow;
if ~isempty(gui_main_handle)&&isvalid(gui_main_handle)
    load_bar_h = getappdata(gui_main_handle,'Loading_bar');
    app_path = get_esp3_prop('app_path');
    if isempty(layers_out)
        layers_out=get_esp3_prop('layers');
    end
    
else
    load_bar_h=[];
    app_path=[];
end

show_status_bar(gui_main_handle);

% processing per script
for i = 1:length(script_files)
    t0=tic;
    
    if isempty(PathToResults)
        if isempty(app_path)
            [PathToResults,~,~] = fileparts(script_files{i});
        else
            PathToResults = app_path.results.Path_to_folder;
        end
    end
    if ~isfolder(PathToResults)
        mkdir(PathToResults);
    end
    
    [~,fff,~]=fileparts(script_files{i});
    error_log_file= fullfile(PathToResults,[fff '_error.log']);
    fid_error=fopen(error_log_file,'w+');
    curr_mbs = script_files{i};
    % step 1: check script and load files
    try
        surv_obj = survey_cl();
        % step 1.1 Check script
        switch origin
            % switch on script type
            
            case 'mbs'
                
                if~strcmp(curr_mbs,'')
                    [ScriptNames,outDir] = get_mbs_from_esp2(cvs_root,'MbsId',curr_mbs,'Rev',[]);
                end
                
                mbs = mbs_cl();
                mbs.readMbsScript(data_root,ScriptNames{1});
                rmdir(outDir,'s');
                
                surv_obj.SurvInput = mbs.mbs_to_survey_obj('type',tag);
                
            case 'xml'
                
                surv_obj.SurvInput = parse_survey_xml(script_files{i});
                
                if isempty(surv_obj.SurvInput)
                    warndlg_perso(gui_main_handle,'',sprintf('Could not parse the XML script file %s.',script_files{i}));
                    continue;
                end
                
                [valid,~] = surv_obj.SurvInput.check_n_complete_input();
                
                if valid == 0
                    str_warn = sprintf('XML script file %s does not appear valid. Please check the script.',script_files{i});
                    warndlg_perso(gui_main_handle,'',str_warn);
                    print_errors_and_warnings(fid_error,'warning',str_warn);
                    continue;
                end
                
        end
        
        
        str_start=sprintf('Processing Script %s started at %s\n',surv_obj.SurvInput.Infos.Title,datestr(now));
        surv_obj.SurvInput.Infos.Script=script_files{i};
        
        disp_perso(gui_main_handle,str_start);
        
        
        fields_req = {};
        %         [snaps,types,strat,trans,regs_trans,cell_trans] = surv_obj.SurvInput.merge_survey_input_for_integration();
        
        % step 1.2 Load files
        [layers_new,layers_old] = surv_obj.SurvInput.load_files_from_survey_input('PathToMemmap',PathToMemmap,'cvs_root',cvs_root,'origin',origin,...
            'layers',layers_out,'Fieldnames',fields_req,'gui_main_handle',gui_main_handle,'PathToResults',PathToResults,'fid_log_file',fid_error,...
            'update_display_at_loading',p.Results.update_display_at_loading);
        
    catch err
        
        print_errors_and_warnings(fid_error,'error',err);
        warndlg_perso(gui_main_handle,'',sprintf('Script file %s could not be loaded.',script_files{i}));
        fclose(fid_error);
        continue;
        
    end
    
    if ~surv_obj.SurvInput.Options.RunInt>0
        t1=toc(t0);
        dt=duration([0 0 t1]);
        disp_str=sprintf('Not running integration for this script.\nTime elapsed to process  %s: %s',script_files{i},dt);
        disp_perso(gui_main_handle,disp_str);
        print_errors_and_warnings(fid_error,'',disp_str);
        fclose(fid_error);
        continue;
    end
    
    show_status_bar(gui_main_handle);
    % step 3: run the integration script
    
    try
        surv_obj.generate_output_v2(layers_new,'PathToResults',PathToResults,'load_bar_comp', load_bar_h,'fid_log_file',fid_error,'gui_main_handle',gui_main_handle);
    catch err
        disp_perso(gui_main_handle,err.message);
        warndlg_perso(gui_main_handle,'',sprintf('Script file %s could not be run.',script_files{i}));
    end
    hide_status_bar(gui_main_handle);
    surv_objs_out=[surv_objs_out surv_obj];
    
    if p.Results.discard_loaded_layers&&numel(layers_new)>1
        layers_new=layers_new.delete_layers({});
    end
    layers_out = [layers_old layers_new];
    
    str_fname=generate_valid_filename(surv_obj.SurvInput.Infos.Title);
    
    outputFiles={...
        fullfile(PathToResults,[str_fname '_xls_output.xlsx']),...
        fullfile(PathToResults,[str_fname '_survey_output.mat']),...
        fullfile(PathToResults,[str_fname '_mbs_output.txt'])};
    
    for ifi=1:numel(outputFiles)
        [~,~,ext]=fileparts(outputFiles{ifi});
        try
            switch ext
                case '.txt'
                    surv_obj.print_output(outputFiles{ifi});
                case '.xlsx'
                    surv_obj.print_output_xls(outputFiles{ifi});
                case '.mat'
                    save(outputFiles{ifi},'surv_obj');
                otherwise
                    continue;
            end
            disp_str=sprintf('Results saved to %s',outputFiles{ifi});
            disp_perso(gui_main_handle,disp_str);
            print_errors_and_warnings(fid_error,'',disp_str);
        catch err
            war_str=sprintf('Could not save results for survey described in file %s to %s \n',script_files{i},outputFiles{ifi});
            print_errors_and_warnings(fid_error,'warning',war_str);
            print_errors_and_warnings(fid_error,'error',err);
        end
    end
    t1=toc(t0);
    dt=duration([0 0 t1]);
    disp_str=sprintf('Time elapsed to process  %s: %s',script_files{i},dt);
    disp_perso(gui_main_handle,disp_str);
    print_errors_and_warnings(fid_error,'',disp_str);
    fclose(fid_error);
end

if ~isempty(layers_out)
    esp3_obj.layers = layers_out;
    esp3_obj.set_layer(layers_out(end));
end
loadEcho(gui_main_handle);
% hide status bar
hide_status_bar(gui_main_handle);


end