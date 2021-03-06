%% load_processing_tab.m
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
% * |main_figure|: TODO: write description and info on variable
% * |option_tab_panel|: TODO: write description and info on variable
%
% *OUTPUT VARIABLES*
%
% NA
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2017-03-28: header (Alex Schimel)
% * YYYY-MM-DD: first version (Yoann Ladroit)
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function load_processing_tab(main_figure,option_tab_panel)

processing_tab_comp.processing_tab = uitab(option_tab_panel,'Title','Processing','Tag','proc');
gui_fmt = init_gui_fmt_struct();
gui_fmt.txt_w = gui_fmt.txt_w*1.5;

pos = cell(8,4);
for j = 1:8
    for i = 1:4
        pos{j,i} = [gui_fmt.x_sep+(i-1)*(gui_fmt.x_sep+gui_fmt.txt_w+gui_fmt.x_sep) gui_fmt.y_sep+(j-1)*(gui_fmt.y_sep+gui_fmt.txt_h)  gui_fmt.txt_w gui_fmt.txt_h];
    end
end
pos = flipud(pos);

% channel selection
uicontrol(processing_tab_comp.processing_tab,gui_fmt.txtStyle,'String','Channel:','Position',pos{1,1});
processing_tab_comp.tog_freq = uicontrol(processing_tab_comp.processing_tab,gui_fmt.popumenuStyle,...
    'String','--',...
    'Value',1,...
    'Position',pos{1,2},...
    'Callback',{@tog_freq,main_figure});

% algos checkboxes
processing_tab_comp.bot_detec      = uicontrol(processing_tab_comp.processing_tab,gui_fmt.chckboxStyle,'Value',0,'String','Bottom Detection V1','Position',pos{2,1});
processing_tab_comp.bot_detec_v2   = uicontrol(processing_tab_comp.processing_tab,gui_fmt.chckboxStyle,'Value',0,'String','Bottom Detection V2','Position',pos{3,1});
processing_tab_comp.bot_feat       = uicontrol(processing_tab_comp.processing_tab,gui_fmt.chckboxStyle,'Value',0,'String','Bottom Features','Position',pos{4,1});
processing_tab_comp.bad_transmit   = uicontrol(processing_tab_comp.processing_tab,gui_fmt.chckboxStyle,'Value',0,'String','Bad Pings Detection','Position',pos{5,1});
processing_tab_comp.spikes_removal = uicontrol(processing_tab_comp.processing_tab,gui_fmt.chckboxStyle,'Value',0,'String','Spikes Detection','Position',pos{6,1});
processing_tab_comp.noise_removal  = uicontrol(processing_tab_comp.processing_tab,gui_fmt.chckboxStyle,'Value',0,'String','Denoise','Position',pos{2,2});
processing_tab_comp.school_detec   = uicontrol(processing_tab_comp.processing_tab,gui_fmt.chckboxStyle,'Value',0,'String','School Detection','Position',pos{3,2});
processing_tab_comp.single_target  = uicontrol(processing_tab_comp.processing_tab,gui_fmt.chckboxStyle,'Value',0,'String','Single Target Detection','Position',pos{4,2});
processing_tab_comp.track_target   = uicontrol(processing_tab_comp.processing_tab,gui_fmt.chckboxStyle,'Value',0,'String','Target Tracking','Position',pos{5,2});


% setting callback for checkboxes
set([processing_tab_comp.track_target ...
    processing_tab_comp.single_target ...
    processing_tab_comp.noise_removal ...
    processing_tab_comp.spikes_removal ...
    processing_tab_comp.bad_transmit ...
    processing_tab_comp.bot_detec ...
    processing_tab_comp.bot_detec_v2 ...
    processing_tab_comp.bot_feat ...
    processing_tab_comp.school_detec]...
    ,'Callback',{@update_process_list,main_figure});

% buttons
uicontrol(processing_tab_comp.processing_tab,gui_fmt.pushbtnStyle,'String','Apply to current layer','pos',pos{3,3},'callback',{@process,main_figure,0});
uicontrol(processing_tab_comp.processing_tab,gui_fmt.pushbtnStyle,'String','Apply to all loaded layers','pos',pos{4,3},'callback',{@process,main_figure,1});
uicontrol(processing_tab_comp.processing_tab,gui_fmt.pushbtnStyle,'String','Select *.raw files','pos',pos{5,3},'callback',{@process,main_figure,2});
processing_tab_comp.save_results = uicontrol(processing_tab_comp.processing_tab,gui_fmt.chckboxStyle,'Value',0,'String','Save Results','Position',pos{6,3});

setappdata(main_figure,'Processing_tab',processing_tab_comp);

end

%% callback buttons
function process(~,~,main_figure,mode)

update_process_list([],[],main_figure);

layer_curr          = get_current_layer();
curr_disp=get_esp3_prop('curr_disp');
layers              = get_esp3_prop('layers');
process_list        = get_esp3_prop('process');
app_path            = get_esp3_prop('app_path');
load_bar_comp       = getappdata(main_figure,'Loading_bar');
processing_tab_comp = getappdata(main_figure,'Processing_tab');

show_status_bar(main_figure);

if mode==0
    % "Apply to current layer"
    layer_to_proc = layer_curr;
    
elseif mode ==1
    % "Apply to all loaded layers"
    layer_to_proc = layers;
    
elseif mode==2
    % "Select *.raw files"
    
    % Get a default path for the file selection dialog box
    if ~isempty(layer_curr)
        [path_lay,~] = layer_curr.get_path_files();
        if ~isempty(path_lay)
            % if file(s) already loaded, same path as first one in list
            file_path = path_lay{1};
        else
            % config default path if none
            file_path = app_path.data.Path_to_folder;
        end
    else
        % config default path if none
        file_path = app_path.data.Path_to_folder;
    end
    [Filename,path_f] = uigetfile( {fullfile(file_path,'*.raw')}, 'Pick a set of raw file','MultiSelect','on');
    if isempty(Filename)
        return;
    end
    
    % single file is char. Turn to cell
    if ~iscell(Filename)
        if (Filename==0)
            return;
        end
        Filename = {Filename};
    end
    
    % keep only supported files, exit if none
    idx_keep =~ cellfun(@isempty,regexp(Filename(:),'(raw$)'));
    Filename = Filename(idx_keep);
    if isempty(Filename)
        return;
    end
    
    % fullfile to all layers
    layer_to_proc = cellfun(@(x) fullfile(path_f,x),Filename,'UniformOutput',0);
    
end

show_status_bar(main_figure);

% process per layer
for ii = 1:length(layer_to_proc)
    
    % get layer
    switch mode
        case {0,1}
            layer = layer_to_proc(ii);
        case {2}
            % file may still need to be opened
            layer = open_file_standalone(layer_to_proc{ii},{},'PathToMemmap',app_path.data_temp.Path_to_folder,'load_bar_comp',load_bar_comp);
            load_bar_comp.progress_bar.setText('Updating Database with GPS Data');
            [~,idx_freq] = layer.get_trans(curr_disp);
            layer.add_ping_data_to_db(idx_freq,0);
    end
    layers_Str_comp=list_layers(layer);
    load_bar_comp.progress_bar.setText(sprintf('Processing %s',layers_Str_comp));
    % process per frequency with algos to apply
    for kk = 1:length(process_list)
        
        if isempty(process_list(kk).Algo)
            continue;
        end
        
        % get transceiver object
        trans_obj = layer.get_trans(process_list(kk).Freq);
        
        if isempty(trans_obj)
            fprintf('Could not find %.0f kHz on this layer\n',process_list(kk).Freq/1e3);
            continue;
        end
        
        [~,idx_algo_denoise,noise_rem_algo]      = find_process_algo(process_list,process_list(kk).Freq,'Denoise');
        [~,idx_algo_bot,bot_algo]                = find_process_algo(process_list,process_list(kk).Freq,'BottomDetection');
        [~,idx_algo_bot_v2,bot_algo_v2]          = find_process_algo(process_list,process_list(kk).Freq,'BottomDetectionV2');
        [~,idx_algo_sr,sr_algo]                  = find_process_algo(process_list,process_list(kk).Freq,'SpikesRemoval');
        [~,idx_algo_bp,bad_trans_algo]           = find_process_algo(process_list,process_list(kk).Freq,'BadPingsV2');
        [~,idx_school_detect,school_detect_algo] = find_process_algo(process_list,process_list(kk).Freq,'SchoolDetection');
        [~,idx_single_target,single_target_algo] = find_process_algo(process_list,process_list(kk).Freq,'SingleTarget');
        [~,idx_track_target,single_track_algo]   = find_process_algo(process_list,process_list(kk).Freq,'TrackTarget');
        [~,idx_algo_botfeat,algo_botfeat]        = find_process_algo(process_list,process_list(kk).Freq,'BottomFeatures');

        if noise_rem_algo
            trans_obj.add_algo(process_list(kk).Algo(idx_algo_denoise));
            trans_obj.apply_algo('Denoise','load_bar_comp',load_bar_comp);
        end
        
        if bot_algo
            trans_obj.add_algo(process_list(kk).Algo(idx_algo_bot));
            trans_obj.apply_algo('BottomDetection','load_bar_comp',load_bar_comp);
        end
        
        if bot_algo_v2
            trans_obj.add_algo(process_list(kk).Algo(idx_algo_bot_v2));
            trans_obj.apply_algo('BottomDetectionV2','load_bar_comp',load_bar_comp);
        end
        
        if sr_algo
            trans_obj.add_algo(process_list(kk).Algo(idx_algo_sr));
            trans_obj.apply_algo('SpikesRemoval','load_bar_comp',load_bar_comp);
        end
        
        if bad_trans_algo
            trans_obj.add_algo(process_list(kk).Algo(idx_algo_bp));
            trans_obj.apply_algo('BadPingsV2','load_bar_comp',load_bar_comp);
        end
        
        if algo_botfeat
            trans_obj.add_algo(process_list(kk).Algo(idx_algo_botfeat));
            trans_obj.apply_algo('BottomFeatures','load_bar_comp',load_bar_comp);
        end
        
        if school_detect_algo
            trans_obj.add_algo(process_list(kk).Algo(idx_school_detect));
            trans_obj.apply_algo('SchoolDetection','load_bar_comp',load_bar_comp);
        end
        
        if single_target_algo
            trans_obj.add_algo(process_list(kk).Algo(idx_single_target));
            trans_obj.apply_algo('SingleTarget','load_bar_comp',load_bar_comp);
            if single_track_algo
                trans_obj.add_algo(process_list(kk).Algo(idx_track_target));
                trans_obj.apply_algo('TrackTarget','load_bar_comp',load_bar_comp);
            end
        end
    end
    
    if mode==2 || processing_tab_comp.save_results.Value>0
        load_bar_comp.progress_bar.setText('Saving Resulting Bottom and regions');
        layer.write_reg_to_reg_xml();
        layer.write_bot_to_bot_xml();
        if mode==2
            layer.rm_memaps([]);
            delete(layer);
        end
    end
    
end

hide_status_bar(main_figure);
set_esp3_prop('layers',layers);

update_display(main_figure,1,1);

end


%% update the list of algorithms to be applied
function update_process_list(~,~,main_figure)

update_algos(main_figure)

layer               = get_current_layer();
process_list        = get_esp3_prop('process');
processing_tab_comp = getappdata(main_figure,'Processing_tab');

idx_freq = get(processing_tab_comp.tog_freq, 'value');

trans_obj = layer.Transceivers(idx_freq);

if isempty(trans_obj.Algo)
    return;
end

add = get(processing_tab_comp.bot_feat,'value')==get(processing_tab_comp.bot_feat,'max');
idx_algo = find_algo_idx(trans_obj,'BottomFeatures');
process_list = process_list.set_process_list(layer.Frequencies(idx_freq),trans_obj.Algo(idx_algo),add);

add=get(processing_tab_comp.noise_removal,'value')==get(processing_tab_comp.noise_removal,'max');
idx_algo=find_algo_idx(trans_obj,'Denoise');
process_list=process_list.set_process_list(layer.Frequencies(idx_freq),trans_obj.Algo(idx_algo),add);

add=get(processing_tab_comp.bot_detec,'value')==get(processing_tab_comp.bot_detec,'max');
idx_algo=find_algo_idx(trans_obj,'BottomDetection');
process_list=process_list.set_process_list(layer.Frequencies(idx_freq),trans_obj.Algo(idx_algo),add);

add=get(processing_tab_comp.bot_detec_v2,'value')==get(processing_tab_comp.bot_detec_v2,'max');
idx_algo=find_algo_idx(trans_obj,'BottomDetectionV2');
process_list=process_list.set_process_list(layer.Frequencies(idx_freq),trans_obj.Algo(idx_algo),add);

add=get(processing_tab_comp.bad_transmit,'value')==get(processing_tab_comp.bad_transmit,'max');
idx_algo=find_algo_idx(trans_obj,'BadPingsV2');
process_list=process_list.set_process_list(layer.Frequencies(idx_freq),trans_obj.Algo(idx_algo),add);

add=get(processing_tab_comp.spikes_removal,'value')==get(processing_tab_comp.spikes_removal,'max');
idx_algo=find_algo_idx(trans_obj,'SpikesRemoval');
process_list=process_list.set_process_list(layer.Frequencies(idx_freq),trans_obj.Algo(idx_algo),add);

add=get(processing_tab_comp.school_detec,'value')==get(processing_tab_comp.school_detec,'max');
idx_algo=find_algo_idx(trans_obj,'SchoolDetection');
process_list=process_list.set_process_list(layer.Frequencies(idx_freq),trans_obj.Algo(idx_algo),add);

add_st=get(processing_tab_comp.single_target,'value')==get(processing_tab_comp.single_target,'max');
idx_algo=find_algo_idx(trans_obj,'SingleTarget');
process_list=process_list.set_process_list(layer.Frequencies(idx_freq),trans_obj.Algo(idx_algo),add_st);

add=get(processing_tab_comp.track_target,'value')==get(processing_tab_comp.track_target,'max');
idx_algo=find_algo_idx(trans_obj,'TrackTarget');
process_list=process_list.set_process_list(layer.Frequencies(idx_freq),trans_obj.Algo(idx_algo),add);

set_esp3_prop('process',process_list);

end

%% callback channel selection
function tog_freq(src,~,main_figure)

%choose_freq(src,[],main_figure);
%curr_disp=get_esp3_prop('curr_disp');
process_list        = get_esp3_prop('process');
processing_tab_comp = getappdata(main_figure,'Processing_tab');
layer               = get_current_layer();

idx_freq = get(processing_tab_comp.tog_freq,'value');
freq = layer.Frequencies(idx_freq);
%curr_disp.ChannelID=layer.ChannelID{idx_freq};

if ~isempty(process_list)
    % find algos already set for that channel
    [~,~,found]=find_process_algo(process_list,freq,'BottomFeatures');
    botfeat_algo=found;
    [~,~,found]=find_process_algo(process_list,freq,'Denoise');
    noise_rem_algo=found;
    [~,~,found]=find_process_algo(process_list,freq,'BottomDetectionV2');
    bot_algo_v2=found;
    [~,~,found]=find_process_algo(process_list,freq,'BottomDetection');
    bot_algo=found;
    [~,~,found]=find_process_algo(process_list,freq,'SpikesRemoval');
    sr_algo=found;
    [~,~,found]=find_process_algo(process_list,freq,'SingleTarget');
    st_detect_algo=found;
    [~,~,found]=find_process_algo(process_list,freq,'TrackTarget');
    track_targets_algo=found;
    [~,~,found]=find_process_algo(process_list,freq,'BadPingsV2');
    bad_trans_algo=found;
    [~,~,found]=find_process_algo(process_list,freq,'SchoolDetection');
    school_detect_algo=found;
else
    botfeat_algo=0;
    noise_rem_algo=0;
    bot_algo=0;
    bad_trans_algo=0;
    school_detect_algo=0;
    bot_algo_v2=0;
    sr_algo=0;
    st_detect_algo=0;
    track_targets_algo=0;
end

% reset the checkboxes for that channel
set(processing_tab_comp.bot_feat,'value',botfeat_algo);
set(processing_tab_comp.noise_removal,'value',noise_rem_algo);
set(processing_tab_comp.bot_detec,'value',bot_algo);
set(processing_tab_comp.spikes_removal,'value',sr_algo);
set(processing_tab_comp.bot_detec_v2,'value',bot_algo_v2);
set(processing_tab_comp.bad_transmit,'value',bad_trans_algo);
set(processing_tab_comp.school_detec,'value',school_detect_algo);
set(processing_tab_comp.single_target,'value',st_detect_algo);
set(processing_tab_comp.track_target,'value',track_targets_algo);

end

