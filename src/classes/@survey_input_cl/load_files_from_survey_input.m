%% load_files_from_survey_input.m
%
% TODO: write short description of function
%
%% Help
%
% *USE*
%
% TODO: write longer description of function
%
% *INPUT VARIABLES*
%
% * |surv_input_obj|: TODO: write description and info on variable
% * |layers|: TODO: write description and info on variable
% * |origin|: TODO: write description and info on variable
% * |cvs_root|: TODO: write description and info on variable
% * |PathToMemmap|: TODO: write description and info on variable
% * |FieldNames|: TODO: write description and info on variable
% * |gui_main_handle|: TODO: write description and info on variable
%
% *OUTPUT VARIABLES*
%
% * |layers_new|: TODO: write description and info on variable
% * |layers_old|: TODO: write description and info on variable
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2017-07-05: started code cleanup and comment (Alex Schimel)
% * 2015-12-18: first version (Yoann Ladroit).
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function [layers_new,layers_old] = load_files_from_survey_input(surv_input_obj,varargin)

%% Managing input variables

% input parser
p = inputParser;

% add parameters
addRequired(p,'surv_input_obj',@(obj) isa(obj,'survey_input_cl'));
addParameter(p,'layers',layer_cl.empty(),@(obj) isa(obj,'layer_cl'));
addParameter(p,'origin','xml',@ischar);
addParameter(p,'cvs_root','',@ischar);
addParameter(p,'PathToMemmap',tempdir,@ischar);
addParameter(p,'PathToResults',pwd,@ischar);
addParameter(p,'FieldNames',{},@iscell);
addParameter(p,'gui_main_handle',[],@(x)isempty(x)||ishandle(x));
addParameter(p,'update_display_at_loading',ispc(),@(x) isnumeric(x)||islogical(x));
addParameter(p,'fid_log_file',1);

% parse
parse(p,surv_input_obj,varargin{:});

% get results
layers_old      = p.Results.layers;
origin          = p.Results.origin;
cvs_root        = p.Results.cvs_root;
datapath        = p.Results.PathToMemmap;
%FieldNames      = p.Results.FieldNames;
gui_main_handle = p.Results.gui_main_handle;
fid_error  = p.Results.fid_log_file;

war_num=0;
err_num=0;

str_start=sprintf('Files Loading process for script %s started at %s',surv_input_obj.Infos.Title,datestr(now));
print_errors_and_warnings(fid_error,'log',str_start);

%%

if isempty(gui_main_handle)
    gui_main_handle=get_esp3_prop('main_figure');
end

if ~isempty(gui_main_handle)
    load_bar_comp = getappdata(gui_main_handle,'Loading_bar');
else
    load_bar_comp = [];
end

infos      = surv_input_obj.Infos;
regions_wc = surv_input_obj.Regions_WC;
algos_xml      = surv_input_obj.Algos;
snapshots  = surv_input_obj.Snapshots;
cal_opt    = surv_input_obj.Cal;
% [~,~,~,trans_tot,~]=surv_input_obj.merge_survey_input_for_integration();
[snaps,types,strat,trans_tot,regs_trans,cells_trans]=surv_input_obj.merge_survey_input_for_integration();

nb_trans_tot=numel(trans_tot);
layers_new = [];
itr_tot=0;
for isn = 1:length(snapshots)
    snap_num = snapshots{isn}.Number;
    stratum = snapshots{isn}.Stratum;
    type=strjoin(snapshots{isn}.Type, ' and ');
    
    if isfield(snapshots{isn},'Cal_rev')
        try
            svCorr = CVS_CalRevs(cvs_root,'CalRev',snapshots{isn}.Cal_rev);
        catch
            svCorr = 1;
        end
    else
        svCorr = 1;
    end
    
    if isfield(snapshots{isn},'Options')
        options = snapshots{isn}.Options;
    else
        options = surv_input_obj.Options;
    end
    
    try
        cal_snap = get_cal_node(cal_opt,snapshots{isn});
    catch
        cal_snap = cal_opt;
    end
    
    str_tmp=sprintf('Loading files from %s',snapshots{isn}.Folder);
    disp_perso(gui_main_handle,str_tmp);
    print_errors_and_warnings(fid_error,'',str_tmp);
    
    for ist = 1:length(stratum)
        strat_name = stratum{ist}.Name;
        transects = stratum{ist}.Transects;
        cal_strat = get_cal_node(cal_snap,stratum{ist});
        
        if isfield(stratum{ist},'Options')
            options = stratum{ist}.Options;
        end
        
        %         strat_type = stratum{ist}.Type;
        %         strat_radius = stratum{ist}.radius;
        
        for itr = 1:length(transects)
            up_disp_done=0;
            try
                filenames_cell = transects{itr}.files;
                trans_num = transects{itr}.number;
                trans_num_str=strjoin(string(num2str(trans_num')),';');
                try
                    cal = get_cal_node(cal_strat,transects{itr});
                catch
                    cal = cal_strat;
                end
                cal=init_cal_struct(cal);
                show_status_bar(gui_main_handle);
                disp_str=sprintf('Loading Snapshot %.0f Type %s Stratum %s Transect(s) %s',snap_num,type,strat_name,trans_num_str);
                print_errors_and_warnings(fid_error,'',disp_str);
                disp_perso(gui_main_handle,disp_str);
                
                if ~iscell(filenames_cell)
                    filenames_cell = {filenames_cell};
                end
                
                regs = transects{itr}.Regions;
                reg_ver = 0;
                
                for ireg = 1:length(regs)
                    if isfield(regs{ireg},'ver')
                        reg_ver = nanmax(reg_ver,regs{ireg}.ver);
                    end
                end
                
                bot = transects{itr}.Bottom;
                bot_ver = 0;
                
                if isfield(bot,'ver')
                    bot_ver = nanmax(bot_ver,bot.ver);
                end
                
                layers_in = [];
                fType = cell(1,length(filenames_cell));
                already_proc = zeros(1,length(filenames_cell));
                
                for ifiles = 1:length(filenames_cell)
                    
                    fileN = fullfile(snapshots{isn}.Folder,filenames_cell{ifiles});
                    
                    if isfield(transects{itr},'Es60_correction')
                        es_offset = transects{itr}.Es60_correction(ifiles);
                    else
                        es_offset = options.Es60_correction;
                    end
                    
                    if ~isempty(layers_old)
                        [idx_lays_no_f,found_lay_no_f] = layers_old.find_layer_idx_files_path(fileN);
                        [idx_lays,found_lay] = layers_old.find_layer_idx_files_path(fileN,'Frequencies',unique([options.Frequency options.FrequenciesToLoad]));
                    else
                        idx_lays_no_f = [];
                        found_lay_no_f = 0;
                        idx_lays= [];
                        found_lay = 0;
                    end
                    
                    if found_lay_no_f==1&&found_lay==0
                        layers_old(idx_lays_no_f)=[];
                    end
                    
                    if ~isempty(layers_new)
                        [idx_lay_new,found_lay_new] = layers_new.find_layer_idx_files_path(fileN,'Frequencies',unique([options.Frequency options.FrequenciesToLoad]));
                    else
                        found_lay_new = 0;
                    end
                    
                    if ~isempty(layers_in)
                        [idx_lay_in,found_lay_in] = layers_in.find_layer_idx_files_path(fileN,'Frequencies',unique([options.Frequency options.FrequenciesToLoad]));
                    else
                        found_lay_in = 0;
                    end
                    
                    
                    abs_f=options.FrequenciesToLoad;
                    alpha_tot=nan(size(options.FrequenciesToLoad));
                    for ui=1:numel(abs_f)
                        if ~isnan(options.Absorption(options.FrequenciesToLoad == abs_f(ui)))
                            alpha_tot(ui)=options.Absorption(options.FrequenciesToLoad == abs_f(ui))/1e3;
                            no_abs=0;
                        else
                            try
                                idx_abs=cal.FREQ == options.FrequenciesToLoad(ui);
                                if any(idx_cal)
                                    alpha_tot(ui)=cal.alpha(idx_abs)/1e3;
                                end
                                no_abs=0;
                            catch
                                no_abs=1;
                            end
                        end
                        
                        if no_abs>0
                            disp_str=sprintf('No absorption specified for Frequency %.0f kHz. Using file value',options.FrequenciesToLoad(ui)/1e3);
                            disp_perso(p.Results.gui_main_handle,disp_str);
                            print_errors_and_warnings(fid_error,'',disp_str);
                        end
                    end
                    
                    env_data_opt=env_data_cl(...
                        'Soundspeed',options.Soundspeed,...
                        'Temperature',options.Temperature,...
                        'Depth',options.MeanDepth,...
                        'Salinity',options.Salinity,...
                        'SVP',options.SVP_profile,...
                        'CTD',options.CTD_profile);
                    
                    if found_lay_in == 1
                        fType{ifiles} = layers_in(idx_lay_in(1)).Filetype;
                        layers_in(idx_lay_in(1)).set_EnvData(env_data_opt);
                        layers_in(idx_lay_in(1)).layer_computeSpSv('calibration',cal,...
                            'absorption_f',abs_f,...
                            'absorption',alpha_tot);
                        continue;
                    end
                    
                    if found_lay_new == 1
                        fType{ifiles} = layers_new(idx_lay_new(1)).Filetype;
                        already_proc(ifiles) = 1;
                        layers_new(idx_lay_new(1)).set_EnvData(env_data_opt);
                        layers_new(idx_lay_new(1)).layer_computeSpSv('calibration',cal,...
                            'absorption_f',abs_f,...
                            'absorption',alpha_tot);
                        continue;
                    end
                    
                    if found_lay>0
                        layers_old(idx_lays(1)).set_EnvData(env_data_opt);
                        layers_old(idx_lays(1)).layer_computeSpSv('calibration',cal,...
                            'absorption_f',abs_f,...
                            'absorption',alpha_tot);
                        layers_in = union(layers_in,layers_old(idx_lays(1)));
                        fType{ifiles} = layers_old(idx_lays(1)).Filetype;
                        layers_old(idx_lays(1)) = [];
                        continue;
                    else
                        if exist(fileN,'file') == 2
                            
                            fType{ifiles} = get_ftype(fileN);
                            if strcmp(fType{ifiles},'CREST')
                                dfile=1;
                            else
                                dfile=0;
                            end
                            [new_lay,~]=open_file_standalone(fileN,fType{ifiles},...
                                'PathToMemmap',datapath,...
                                'Frequencies',unique([options.Frequency options.FrequenciesToLoad]),...
                                'Channels',unique([options.Channel options.ChannelsToLoad]),...
                                'EnvData',env_data_opt,...
                                'absorption',alpha_tot,...
                                'absorption_f',abs_f,...
                                'EsOffset',es_offset,...
                                'calibration',cal,...
                                'load_bar_comp',load_bar_comp,...
                                'LoadEKbot',1,'CVSCheck',0,...
                                'force_open',1,...
                                'bot_ver',[],...
                                'reg_ver',[],...
                                'CVSroot',cvs_root,'dfile',dfile,'CVSCheck',0,'SvCorr',svCorr);
                            
                            if isempty(new_lay)
                                continue;
                            end
                            [idx,found] = new_lay.find_freq_idx(options.Frequency);
                            if found == 0
                                war_str=sprintf('Cannot file required Frequency in file %s',filenames_cell{ifiles});
                                print_errors_and_warnings(fid_error,'warning',war_str);
                                war_num=war_num+1;
                                
                                continue;
                            end
                            
                            if ~ismember(lower(fType{ifiles}),{'ek60' 'ek80' 'raw' 'asl' 'crest'})
                                war_str=sprintf('Unrecognized file type for file %s',fileN);
                                print_errors_and_warnings(fid_error,'warning',war_str);
                                war_num=war_num+1;
                                continue
                            end
                            
                            
                            switch origin
                                case 'mbs'
                                    new_lay.OriginCrest = transects{itr}.OriginCrest{ifiles};
                                    new_lay.CVS_BottomRegions(cvs_root);
                                    surv = survey_data_cl('Voyage',infos.Voyage,'SurveyName',infos.SurveyName,...
                                        'Snapshot',snap_num,'Stratum',strat_name,'Transect',trans_num);
                                    new_lay.set_survey_data(surv);
                                    
                                    switch lower(fType{ifiles})
                                        case {'ek60','ek80','raw'}
                                            new_lay.update_echo_logbook_dbfile('main_figure',gui_main_handle);
                                            new_lay.write_reg_to_reg_xml();
                                            new_lay.write_bot_to_bot_xml();
                                    end
                            end
                            
                            layers_in = union(layers_in,new_lay);
                            clear new_lay;
                            
                        else
                            
                            war_str=sprintf('Cannot Find specified file %s',filenames_cell{ifiles});
                            print_errors_and_warnings(fid_error,'warning',war_str);
                            war_num=war_num+1;
                            
                            continue;
                            
                        end
                    end
                end
                
                if all(already_proc)
                    continue;
                end
                
                if isempty(layers_in)
                    
                    war_str=sprintf('Could not find any files in  Snapshot %.0f Type %s Stratum %s Transect %s',snap_num,type,strat_name,trans_num_str);
                    print_errors_and_warnings(fid_error,'warning',war_str);
                    war_num=war_num+1;
                    continue;
                end
                
                fType_in = cell(1,length(layers_in));
                dates_out = nan(1,length(layers_in));
                for ilay_in = 1:length(layers_in)
                    fType_in{ilay_in} = layers_in(ilay_in).Filetype;
                    dates_out(ilay_in) = layers_in(ilay_in).Transceivers(1).Time(1);
                end
                
                switch origin
                    case 'xml'
                        
                        [fTypes,idx_unique,idx_out] = unique(fType_in);
                        
                        for itype = 1:length(fTypes)
                            
                            switch lower(fTypes{itype})
                                
                                case 'asl'
                                    
                                    max_load_days = 1;
                                    i_cell = 1;
                                    new_layers_sorted{i_cell} = [];
                                    date_ori = dates_out(1);
                                    
                                    for i_file = 1:length(dates_out)
                                        if i_file>1
                                            if dates_out(i_file)-dates_out(i_file-1) >= 1
                                                i_cell = i_cell+1;
                                                new_layers_sorted{i_cell} = layers_in(i_file);
                                                date_ori = dates_out(i_file);
                                                continue;
                                            end
                                        end
                                        
                                        if dates_out(i_file)-date_ori <= max_load_days
                                            new_layers_sorted{i_cell} = [new_layers_sorted{i_cell} layers_in(i_file)];
                                        else
                                            i_cell = i_cell+1;
                                            new_layers_sorted{i_cell} = layers_in(i_file);
                                            date_ori = dates_out(i_file);
                                        end
                                        
                                    end
                                    
                                    disp_perso(gui_main_handle,'Shuffling layers');
                                    layers_out_temp = [];
                                    
                                    for icell = 1:length(new_layers_sorted)
                                        layers_out_temp = union(layers_out_temp,shuffle_layers(new_layers_sorted{icell},'multi_layer',-1));
                                    end
                                    
                                    clear layers_in;
                                    clear new_layers_sorted;
                                    
                                otherwise
                                    
                                    layers_out_temp = shuffle_layers(layers_in(idx_unique(itype) == idx_out),'multi_layer',0);
                                    clear layers_in;
                                    
                            end
                        end
                        
                    case 'mbs'
                        layers_out_temp = layers_in;
                        clear layers_in;
                end
                
                if ~isempty(load_bar_comp)
                    load_bar_comp.progress_bar.setText('');
                end
                
                if numel(layers_out_temp)>numel(trans_num)
                    disp_str=sprintf('Non continuous files in Snapshot %.0f Type %s Stratum %s Transect(s)%s',snap_num,type,strat_name,trans_num_str);
                    disp_perso(p.Results.gui_main_handle,disp_str);
                    print_errors_and_warnings(fid_error,'',disp_str);
                end
                
                
                for i_lay = 1:length(layers_out_temp)
                    layer_new = layers_out_temp(i_lay);
                    survey_data_obj=layer_new.list_layers_survey_data();
                    curr_disp_struct_tmp.ChannelID=options.Channel;
                    curr_disp_struct_tmp.Freq=options.Frequency;
                    
                    [trans_obj_primary,idx_primary] = layer_new.get_trans(curr_disp_struct_tmp);
                    
                    idx_secondary=[];
                    for ifreq = 1:length(options.FrequenciesToLoad)
                        if ~isempty(options.ChannelsToLoad)
                            curr_disp_struct_sec_tmp.ChannelID=options.ChannelsToLoad{ifreq};
                        end
                        curr_disp_struct_sec_tmp.Freq=options.FrequenciesToLoad(ifreq);
                        [trans_obj_sec,i_freq] = layer_new.get_trans(curr_disp_struct_sec_tmp);
                        idx_secondary=union(idx_secondary,i_freq);
                        found =~isempty(trans_obj_sec);
                        
                        if found==0
                            war_str=sprintf('Could not find %.0f kHz in  Snapshot %.0f Type %s Stratum %s Transect %s',options.FrequenciesToLoad(ifreq)/1e3,snap_num,type,strat_name,trans_num_str);
                            print_errors_and_warnings(fid_error,'warning',war_str);
                            war_num=war_num+1;
                            continue;
                        end
                        
                        switch origin
                            case 'xml'
                                layer_new.load_bot_regs('Frequencies',unique([options.Frequency options.FrequenciesToLoad]),...
                                    'Channels',unique([options.Channel options.ChannelsToLoad]),...
                                    'bot_ver',bot_ver,'reg_ver',reg_ver);
                        end
                        
                        if options.Motion_correction
                            create_motion_comp_subdata(layer_new,i_freq,0);
                        end
                        
                    end
                    
                    bot_copied = false;
                    
                    for ial = 1:length(algos_xml)
                        
                        if  ~ismember(algos_xml{ial}.Name,{'BottomDetection' 'BottomDetectionV2' 'DropOuts' 'SpikesRemoval' 'BadPingsV2' 'Denoise'})&&~bot_copied
                            if options.CopyBottomFromFrequency>0
                                bot_copied = true;
                                idx_other=[];
                                for ifreq = 1:length(options.FrequenciesToLoad)
                                    [i_freq,found]=layer_new.find_freq_idx(options.FrequenciesToLoad(ifreq));
                                    if found>0
                                        idx_other=union(i_freq,idx_other) ;
                                    end
                                end
                                
                                if ~isempty(idx_other)
                                    [idx_bot_freq,found]=layer_new.find_freq_idx(options.Frequency);
                                    if found==0
                                        disp_perso(gui_main_handle,'Could not find frequency to copy bottom from');
                                        print_errors_and_warnings(fid_error,'','Could not find frequency to copy bottom from');
                                    else
                                        [bots,ifreq_b]=layer_new.generate_bottoms_for_other_freqs(idx_bot_freq(1),idx_other);
                                        
                                        for ifreq=1:numel(ifreq_b)
                                            layer_new.Transceivers(ifreq_b(ifreq)).Bottom=bots(ifreq);
                                        end
                                    end
                                end
                            end
                            
                        end
                        
                        disp_str=sprintf('Applying %s',algos_xml{ial}.Name);
                        disp_perso(p.Results.gui_main_handle,disp_str);
                        print_errors_and_warnings(fid_error,'',disp_str);
                        
                        
                        try
                            if isempty(algos_xml{ial}.Varargin.Frequencies)
                                idx_chan=idx_primary;
                                found_freq_al=1;
                            else
                                [idx_chan,found_freq_al] = layer_new.find_freq_idx(algos_xml{ial}.Varargin.Frequencies);
                                idx_chan(found_freq_al==0)=[];
                            end
                            
                            idx_not_found=find(found_freq_al==0);
                            
                            for f_nf = idx_not_found
                                disp_str=sprintf('Could not find Frequency %.0f kHz. Algo %s not applied on it',algos_xml{ial}.Varargin.Frequencies(f_nf)/1e3,algos_xml{ial}.Name);
                                disp_perso(p.Results.gui_main_handle,disp_str);
                                print_errors_and_warnings(fid_error,'',disp_str);
                            end
                            
                            if ~isempty(idx_chan)
                                layer_new.add_algo(algo_cl('Name',algos_xml{ial}.Name,'Varargin',algos_xml{ial}.Varargin),'idx_chan',idx_chan);
                                layer_new.apply_algo(algos_xml{ial}.Name,'idx_chan',idx_chan,...
                                    'timeBounds',[survey_data_obj.StartTime survey_data_obj.EndTime],...
                                    'load_bar_comp',load_bar_comp,'survey_options',surv_input_obj.Options);
                            end
                            
                            if ismember(algos_xml{ial}.Name,{'SingleTarget' 'TrackTarget'})
                                for i_freq_al = idx_chan
                                    %lay_name=list_layers(layer_new,'nb_char',80);
                                    surv_tmp = layer_new.SurveyData;
                                    for isur=1:numel(surv_tmp)
                                        fname=generate_valid_filename(surv_tmp{isur}.print_survey_data());
                                        switch algos_xml{ial}.Name
                                            case 'SingleTarget'
                                                if options.Export_ST==1
                                                    file_st=fullfile(p.Results.PathToResults,sprintf('%s_ST_%.0f.xlsx',fname,layer_new.Frequencies(idx_chan)));
                                                    layer_new.Transceivers(idx_chan).save_st_to_xls(file_st,0,surv_tmp{isur}.StartTime,surv_tmp{isur}.EndTime);
                                                end
                                            case 'TrackTarget'
                                                if options.Export_ST==2||options.Export_TT==1
                                                    file_tt=fullfile(p.Results.PathToResults,sprintf('%s_TT_%.0f.xlsx',fname,layer_new.Frequencies(idx_chan)));
                                                    layer_new.Transceivers(idx_chan).save_tt_to_xls(file_tt,surv_tmp{isur}.StartTime,surv_tmp{isur}.EndTime);
                                                end
                                        end
                                    end
                                end
                            end
                            
                        catch err_1
                            war_str=sprintf('Error while applying %s',algos_xml{ial}.Name);
                            print_errors_and_warnings(fid_error,'warning',war_str);
                            print_errors_and_warnings(fid_error,'error',err_1);
                            err_num=err_num+1;
                            
                        end
                    end
                    
                    if options.SaveBot>0
                        layer_new.write_bot_to_bot_xml();
                    end
                    
                    for ire = 1:length(regs)
                        if isfield(regs{ire},'name')
                            switch regs{ire}.name
                                case 'WC'
                                    trans_obj_primary.rm_region_name('WC');
                                    for irewc = 1:length(regions_wc)
                                        if isfield(regions_wc{irewc},'y_max')
                                            y_max = regions_wc{irewc}.y_max;
                                        else
                                            y_max = inf;
                                        end
                                        if isfield(regions_wc{irewc},'t_min')
                                            t_min = datenum(regions_wc{irewc}.t_min,'yyyy/mm/dd HH:MM:SS');
                                        else
                                            t_min = 0;
                                        end
                                        
                                        if isfield(regions_wc{irewc},'t_max')
                                            t_max = datenum(regions_wc{irewc}.t_max,'yyyy/mm/dd HH:MM:SS');
                                        else
                                            t_max = Inf;
                                        end
                                        
                                        reg_wc = trans_obj_primary.create_WC_region(...
                                            'y_max',y_max,...
                                            'y_min',regions_wc{irewc}.y_min,...
                                            't_min',t_min,...
                                            't_max',t_max,...
                                            'Type',regions_wc{irewc}.Type,...
                                            'Ref',regions_wc{irewc}.Ref,...
                                            'Cell_w',regions_wc{irewc}.Cell_w,...
                                            'Cell_h',regions_wc{irewc}.Cell_h,...
                                            'Cell_w_unit',regions_wc{irewc}.Cell_w_unit,...
                                            'Cell_h_unit',regions_wc{irewc}.Cell_h_unit);
                                        
                                        
                                        trans_obj_primary.add_region(reg_wc,'Split',0);
                                    end
                            end
                        end
                    end
                    
                    for ireg=1:length(trans_obj_primary.Regions)
                        trans_obj_primary.Regions(ireg).Remove_ST=options.Remove_ST;
                    end
                    
                    
                    if options.Remove_tracks
                        trans_obj_primary.create_track_regs('Type','Bad Data');
                    end
                    if options.SaveReg>0
                        layer_new.write_reg_to_reg_xml();
                    end
                    
                    layers_new = union(layers_new,layer_new);
                    set_esp3_prop('layers',[layers_old layers_new]);
                    set_current_layer(layer_new);
                    
                    if ~isempty(gui_main_handle)
                        if p.Results.update_display_at_loading>0
                            try
                                loadEcho(gui_main_handle,1,1);
                                up_disp_done=1;
                            catch err_3
                                print_errors_and_warnings(fid_error,'error',err_3);
                            end
                        end
                    end
                    
                end
                clear layers_out_temp;
                
            catch err
                
                war_str=sprintf('Error opening file for Snapshot %.0f Type %s Stratum %s Transect %s',snap_num,type,strat_name,trans_num_str);
                print_errors_and_warnings(fid_error,'warning',war_str);
                print_errors_and_warnings(fid_error,'error',err);
                err_num=err_num+1;
                
            end
            itr_tot=itr_tot+1;
            if ~isempty(load_bar_comp)
                set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',nb_trans_tot,'Value',itr_tot);
            end
        end
    end
end

if p.Results.update_display_at_loading==0||up_disp_done==0
    try
        loadEcho(gui_main_handle,1,1);
    catch err_3
        print_errors_and_warnings(fid_error,'error',err_3);
    end
end


hide_status_bar(gui_main_handle);
sum_str=sprintf(['\n Files loading process for script %s finished with:\n' ...
    '%d Warnings\n'...
    '%d Errors \n\n']...
    ,surv_input_obj.Infos.Title,war_num,err_num);

print_errors_and_warnings(fid_error,'',sum_str);

str_end=sprintf('Files Loading process for script %s finished at %s\n',surv_input_obj.Infos.Title,datestr(now));
print_errors_and_warnings(fid_error,'',str_end);


end

%% sub-functions

function cal = get_cal_node(cal_ori,node)

cal = cal_ori;

if ~isempty(node.Cal)
    
    cal_temp_cell = node.Cal;
    
    if ~iscell(cal_temp_cell)
        cal_temp_cell = {cal_temp_cell};
    end
    
    cal = cell(1,length(cal_temp_cell));
    
    for icell = 1:length(cal_temp_cell)
        call_out_temp = [];
        for ical = 1:length(cal_temp_cell{icell})
            cal_temp = cal_temp_cell{icell};
            if ~isempty(cal_ori)
                call_out_temp = cal_ori;
                if any([call_out_temp(:).FREQ] == cal_temp(ical).FREQ)
                    call_out_temp([call_out_temp(:).FREQ] == cal_temp(ical).FREQ) = cal_temp(ical);
                else
                    call_out_temp(length(call_out_temp)+1) = cal_temp(ical);
                end
            else
                call_out_temp = cal_temp;
            end
        end
        cal{icell} = call_out_temp;
    end
    
    if length(cal) == 1
        cal = cal{1};
    end
    
end

end

