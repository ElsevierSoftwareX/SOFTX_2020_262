%% process_surveys.m
%
% Loads and runs a script file, and saves the results in output file
%
%% Help
%
% *USE*
%
% TODO: write longer description of function
%
% *INPUT VARIABLES*
%
% * |input_variable_1|: TODO: write description and info on variable
%
% *OUTPUT VARIABLES*
%
% * |output_variable_1|: TODO: write description and info on variable
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2017-11-16: more code cleanup and commenting (Alex Schimel)
% * 2017-07-05: started code cleanup and comment (Alex Schimel)
% * 2016-??-??: first version (Yoann Ladroit).
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function [layers_out,surv_objs_out] = process_surveys(Script,varargin)

%% Managing input variables

% input parser
p = inputParser;

% add parameters
addRequired(p,'Script',@(x) ischar(x)|iscell(x)); % script file(s)
addParameter(p,'layers',layer_cl.empty(),@(obj) isa(obj,'layer_cl'));
addParameter(p,'origin','xml',@ischar); % script type "xml" or "mbs"
addParameter(p,'cvs_root','',@ischar);
addParameter(p,'data_root','',@ischar);
addParameter(p,'PathToMemmap',tempdir,@ischar);
addParameter(p,'PathToResults','',@ischar);
addParameter(p,'tag','raw',@(x) ischar(x));
addParameter(p,'discard_loaded_layers',0,@isnumeric);
addParameter(p,'update_display_at_loading',ispc(),@(x) isnumeric(x)||islogical(x));
addParameter(p,'gui_main_handle',[],@ishandle);

% parse
parse(p,Script,varargin{:});

% get results
layers_out      = p.Results.layers;
origin          = p.Results.origin;
cvs_root        = p.Results.cvs_root;
data_root       = p.Results.data_root;
PathToMemmap    = p.Results.PathToMemmap;
tag             = p.Results.tag;
gui_main_handle = p.Results.gui_main_handle;

%% processing

surv_objs_out=[];
% check script filenames
if ~iscell(Script)
    Script = {Script};
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




% processing per script
for i = 1:length(Script)
    t0=tic;
    
    PathToFile=p.Results.PathToResults;
    if isempty(PathToFile) 
        if isempty(app_path)
            [PathToFile,~,~] = fileparts(Script{i});
        else
            PathToFile = app_path.results;
        end
    end
    if ~isfolder(PathToFile)
        mkdir(PathToFile);
    end

    [~,fff,~]=fileparts(Script{i});
    error_log_file= fullfile(PathToFile,[fff '_error.log']);
    fid_error=fopen(error_log_file,'w+');
    curr_mbs = Script{i};
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
                
                surv_obj.SurvInput = parse_survey_xml(Script{i});
                
                if isempty(surv_obj.SurvInput)
                    warndlg_perso(gui_main_handle,'',sprintf('Could not parse the XML script file %s.',Script{i}));
                    continue;
                end
                
                [valid,~] = surv_obj.SurvInput.check_n_complete_input();
                
                if valid == 0
                    str_warn = sprintf('XML script file %s does not appear valid. Please check the script.',Script{i});
                    warndlg_perso(gui_main_handle,'',str_warn);
                    print_errors_and_warnings(fid_error,'warning',str_warn);
                    continue;
                end
                
        end
        
        
        str_start=sprintf('Processing Script %s started at %s\n',surv_obj.SurvInput.Infos.Title,datestr(now));
        surv_obj.SurvInput.Infos.Script=Script{i};

        disp_perso(gui_main_handle,str_start);
        
        
        fields_req = {};
%         [snaps,types,strat,trans,regs_trans,cell_trans] = surv_obj.SurvInput.merge_survey_input_for_integration();

        % step 1.2 Load files
        [layers_new,layers_old] = surv_obj.SurvInput.load_files_from_survey_input('PathToMemmap',PathToMemmap,'cvs_root',cvs_root,'origin',origin,...
            'layers',layers_out,'Fieldnames',fields_req,'gui_main_handle',gui_main_handle,'PathToResults',PathToFile,'fid_log_file',fid_error,...
            'update_display_at_loading',p.Results.update_display_at_loading);
        
    catch err
        
        print_errors_and_warnings(fid_error,'error',err);
        warndlg_perso(gui_main_handle,'',sprintf('Script file %s could not be loaded.',Script{i}));
        fclose(fid_error);
        continue;
        
    end
    
    if ~surv_obj.SurvInput.Options.RunInt>0
        t1=toc(t0);
        dt=duration([0 0 t1]);
        disp_str=sprintf('Not running integration for this script.\nTime elapsed to process  %s: %s',Script{i},dt);
        disp_perso(gui_main_handle,disp_str);
        print_errors_and_warnings(fid_error,'',disp_str);
        fclose(fid_error);
        continue;
    end
    
    show_status_bar(gui_main_handle);
    % step 3: run the integration script
    
    try
        surv_obj.generate_output_v2(layers_new,'PathToResults',PathToFile,'load_bar_comp', load_bar_h,'fid_log_file',fid_error,'gui_main_handle',gui_main_handle);
    catch err
        disp_perso(gui_main_handle,err.message);
        warndlg_perso(gui_main_handle,'',sprintf('Script file %s could not be run.',Script{i}));
    end
    hide_status_bar(gui_main_handle);
    surv_objs_out=[surv_objs_out surv_obj];
    
    if p.Results.discard_loaded_layers>0&&numel(layers_new)>1
        layers_new=layers_new.delete_layers({});
    end
    layers_out = [layers_old layers_new];
    
    str_fname=generate_valid_filename(surv_obj.SurvInput.Infos.Title);
    
    outputFiles={...
        fullfile(PathToFile,[str_fname '_xls_output.xlsx']),...
        fullfile(PathToFile,[str_fname '_survey_output.mat']),...
        fullfile(PathToFile,[str_fname '_mbs_output.txt'])};
    
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
            war_str=sprintf('Could not save results for survey described in file %s to %s \n',Script{i},outputFiles{ifi});
            print_errors_and_warnings(fid_error,'warning',war_str);
            print_errors_and_warnings(fid_error,'error',err);
        end
    end
    t1=toc(t0);
    dt=duration([0 0 t1]);
    disp_str=sprintf('Time elapsed to process  %s: %s',Script{i},dt);
    disp_perso(gui_main_handle,disp_str);
    print_errors_and_warnings(fid_error,'',disp_str);
    fclose(fid_error);
    
end


% hide status bar
hide_status_bar(gui_main_handle);


end