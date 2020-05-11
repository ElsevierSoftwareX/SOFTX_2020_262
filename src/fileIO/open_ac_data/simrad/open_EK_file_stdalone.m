%% open_EK_file_stdalone.m
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
% * |Filename_cell|: TODO write description (Required. Char or cell).
% * |PathToMemmap|: TODO write description (Optional. Char, Default: TODO).
% * |Calibration|: TODO write description (Optional. Default: empty num).
% * |Frequencies|: TODO write description (Optional. Default: empty num).
% * |FieldNames|: TODO write description (Optional. Default: empty cell).
% * |EsOffset|: TODO write description (Optional. Default: empty num).
% * |GPSOnly|: TODO write description (Optional. Default: 0).
% * |LoadEKbot|: TODO write description (Optional. Default: 0).
% * |load_bar_comp|: TODO write description (Optional. Default: empty num).
%
% *OUTPUT VARIABLES*
%
% * |layers|: TODO write description,
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2017-04-02: header (Alex Schimel)
% * YYYY-MM-DD: first version (Yoann Ladroit).
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function [layers,id_rem] = open_EK_file_stdalone(Filename_cell,varargin)

p = inputParser;

if ~iscell(Filename_cell)
    Filename_cell = {Filename_cell};
end

if ~iscell(Filename_cell)
    Filename_cell = {Filename_cell};
end

if isempty(Filename_cell)
    id_rem = [];
    layers = [];
    return;
end


[def_path_m,~,~] = fileparts(Filename_cell{1});

if ischar(Filename_cell)
    def_gps_only_val = 0;
else
    def_gps_only_val = zeros(1,numel(Filename_cell));
end

addRequired(p,'Filename_cell',@(x) ischar(x)||iscell(x));
addParameter(p,'PathToMemmap',def_path_m,@ischar);
addParameter(p,'Calibration',[]);
addParameter(p,'Frequencies',[]);
addParameter(p,'Channels',{});
addParameter(p,'FieldNames',{});
addParameter(p,'EsOffset',[]);
addParameter(p,'GPSOnly',def_gps_only_val);
addParameter(p,'LoadEKbot',0);
addParameter(p,'force_open',0);
addParameter(p,'sub_sample',1);
addParameter(p,'load_bar_comp',[]);

parse(p,Filename_cell,varargin{:});

cal = p.Results.Calibration;
vec_freq_init = sort(p.Results.Frequencies);

channels_init = deblank(p.Results.Channels);
load_bar_comp = p.Results.load_bar_comp;

%profile on;
%For further profiling, it looks like the bottle neck is in
% the parsing of NMEA messages coming from the POS/MV, as they are
% recorded at 10Hz, for GPTS and in the match filtering process for WBT
% data...

if numel(p.Results.GPSOnly) ~= numel(Filename_cell)
    GPSOnly = ones(1,numel(Filename_cell))*p.Results.GPSOnly;
else
    GPSOnly = p.Results.GPSOnly;
end



if ~isequal(Filename_cell, 0)
    
    nb_files = numel(Filename_cell);
            if ~isempty(load_bar_comp)
            set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',length(Filename_cell),'Value',0);
            end
    layers(length(Filename_cell)) = layer_cl();
    id_rem = [];
    
  
    
    for uu = 1:nb_files
        
        if ~isempty(load_bar_comp)
            str_disp=sprintf('Opening File %d/%d : %s',uu,nb_files,Filename_cell{uu});
            load_bar_comp.progress_bar.setText(str_disp);
        end

        Filename = Filename_cell{uu};
        [path_f,fileN,~] = fileparts(Filename);
        
        try
            ftype = get_ftype(Filename);
            
            switch ftype
                case 'EK80'
                    [~,config] = read_EK80_config(Filename);
                    
                    frequency = cellfun(@(x) x.Frequency,config);
                    channels = cellfun(@(x) deblank(x.ChannelID),config,'un',0);
                    
                case 'EK60'
                    %fid=fopen(Filename,'r');
                    fid = fopen(Filename,'r','n','US-ASCII');
                    [~, frequency,channels] = readEKRaw_ReadHeader(fid);
                    fclose(fid);
                otherwise
                    continue;
            end
            
            if isempty(frequency)
                warndlg_perso([],'Failed',['Cannot open file ' Filename]);
                continue;
            end
            av_frequencies=frequency;
            av_cids=channels;
            transceivercount = length(frequency);
            
            vec_freq_temp= frequency;
            list_freq_str = cellfun(@(x,y) sprintf('%.0f kHz: %s',x,y),num2cell(frequency/1e3), channels,'un',0);
            
            [vec_freq_temp,idx_s] = sort(vec_freq_temp);
            channels_temp = deblank(channels(idx_s));
             
            if ~all(ismember(vec_freq_init,vec_freq_temp))
                vec_freq_init = [];
            end
            
            idx_common_channels = ismember(channels_temp,channels_init);
            idx_common_freqs = ismember(vec_freq_temp,vec_freq_init);
            fig=findobj(0,'Type','figure','-and','Name','ESP3');
            if (sum(idx_common_channels)==transceivercount||sum(idx_common_channels)==numel(channels_init))&&~isempty(channels_init)
                vec_freq = vec_freq_temp(idx_common_channels);
                channels_sub = channels_temp(idx_common_channels);
            else
                if isempty(vec_freq_init)
                    if GPSOnly(uu) == 0
                        if transceivercount > 1

                            vec_freq_tot = vec_freq_temp;
                            
                            [select,val] = listdlg_perso([],'Choose Channels to load',list_freq_str(idx_s),'timeout',10);
                            
                            %set_figure_state(fig,state_fig);
                            if val==0 || isempty(select)
                                id_rem = [];
                                layers = [];
                                return;
                            else
                                vec_freq = vec_freq_tot(select);
                                channels_sub = channels_temp(select);
                            end
                        else
                            vec_freq = vec_freq_temp;
                            channels_sub = channels_temp;
                        end
                    else
                        vec_freq = vec_freq_temp;
                        channels_sub = channels_temp;
                    end
                else
                    vec_freq = vec_freq_temp(idx_common_freqs);
                    channels_sub = channels_temp(idx_common_freqs);
                end
            end
            

            if isempty(vec_freq)
                vec_freq = -1;
                channels_sub = channels_temp;
            end
            
            vec_freq_init = vec_freq;

            if ~isfolder(fullfile(path_f,'echoanalysisfiles'))
                mkdir(fullfile(path_f,'echoanalysisfiles'));
            end
            
            fileIdx = fullfile(path_f,'echoanalysisfiles',[fileN '_echoidx.mat']);
            
            if ~isfile(fileIdx)
                %idx_raw_obj=idx_from_raw(Filename,p.Results.load_bar_comp);
                idx_raw_obj = idx_from_raw_v2(Filename,p.Results.load_bar_comp);
                save(fileIdx,'idx_raw_obj');
            else
                load(fileIdx);
            end
            
            [~,et] = start_end_time_from_file(Filename);
            
            dgs = find((strcmp(idx_raw_obj.type_dg,'RAW0')|strcmp(idx_raw_obj.type_dg,'RAW3'))&idx_raw_obj.chan_dg==nanmin(idx_raw_obj.chan_dg));
            
            if isempty(dgs)
                if ~isempty(load_bar_comp)
                    load_bar_comp.progress_bar.setText(sprintf('No accoustic data in file %s\n',Filename));
                else
                    fprintf('No accoustic data in file %s\n',Filename);
                end
                id_rem = union(id_rem,uu);
                continue;
            end
            
            if et-idx_raw_obj.time_dg(dgs(end))>2*nanmax(diff(idx_raw_obj.time_dg(dgs)))
                fprintf('Re-Indexing file: %s\n',Filename);
                delete(fileIdx);
                idx_raw_obj = idx_from_raw_v2(Filename,p.Results.load_bar_comp);
                save(fileIdx,'idx_raw_obj');
            end
            
            
            nb_pings=idx_raw_obj.get_nb_pings_per_channels();
            
            if any(nb_pings<=1)
                id_rem=union(id_rem,uu);
                disp_str=sprintf('Only one ping in file %s. Ignoring it.',Filename);
                if ~isempty(load_bar_comp)
                    load_bar_comp.progress_bar.setText(disp_str);
                else
                    disp(disp_str);
                end
                
                continue;
            end
            
            
            [trans_obj,envdata,NMEA,mru0_att] =data_from_raw_idx_cl_v7(path_f,idx_raw_obj,...%new version.3x faster for EK80 files. than v5...
                'Frequencies',vec_freq,...
                'Channels',channels_sub,...
                'GPSOnly',GPSOnly(uu),...
                'FieldNames',p.Results.FieldNames,...
                'PathToMemmap',p.Results.PathToMemmap,...
                'load_bar_comp',p.Results.load_bar_comp);
            
            
            
            if isempty(trans_obj)&&GPSOnly(uu)==0
                id_rem=union(id_rem,uu);
                continue;
            end
            
            if ~isa(trans_obj,'transceiver_cl')
                warndlg_perso([],'','Could not read file.');
                id_rem=union(id_rem,uu);
                continue;
            end
            
            if GPSOnly(uu)==0
                for it=1:length(trans_obj)
                    prop_params=properties(trans_obj(it).Params);
                    for iprop=1:length(prop_params)
                        if~any(ismember(prop_params{iprop},{'Time' 'PingNumber'}))
                            ppp=unique(trans_obj(it).Params.(prop_params{iprop}));
                            if ~iscell(ppp)
                                ppp=ppp(~isnan(ppp));
                            end
                            if length(ppp)>1
                                switch prop_params{iprop}
                                    case {'PulseLength' 'PulseDuration' 'TransmitPower'}
                                        warning('%s parameters changed during file for channel %s\nESP3 takes it into account but this might affect whatever calibration you apply to the file....',prop_params{iprop},trans_obj(it).Config.ChannelID);
                                    otherwise
                                        warning('%s parameters changed during file for channel %s\n Do not use this channel and file with ESP3 yet!',prop_params{iprop},trans_obj(it).Config.ChannelID);
                                end
                            end
                        end
                    end
                end
            end
            
            
            if ~isempty(load_bar_comp)
                load_bar_comp.progress_bar.setText(sprintf('Parsing NMEA from %s',Filename));
            end
            
            
            
            ignore_file=fullfile(path_f,'nmea_ignore.txt');
            NMEA_ignore={};
            if isfile(ignore_file)
                try
                    fid=fopen(ignore_file,'r');
                    tmp=fread(fid,'*char');
                    NMEA_ignore=strsplit(tmp(:)',',');
                    fclose(fid);
                catch
                    disp_str=sprintf('Could not use NMEA Ignore file %s',ignore_file);
                    if isempty(load_bar_comp)
                        fprintf(disp_str,Filename);
                    else
                        load_bar_comp.progress_bar.setText(disp_str);
                    end
                end
            end
            
            NMEA_att=setdiff({'SHR' 'HDT' 'VLW' 'HDG' 'XDR' 'IWAIMU' 'DID'},NMEA_ignore);
            NMEA_gps=setdiff({'GGA' 'GGL' 'RMC'},NMEA_ignore);
            
            
            idx_NMEA_gps=false(numel(NMEA_gps),numel(NMEA.type));
            for ig=1:numel(NMEA_gps)
                idx_NMEA_gps(ig,:)=strcmpi(NMEA.type,NMEA_gps{ig});
            end
            
            [~,idx_GPS]=max(sum(idx_NMEA_gps,2));
            
            ori_gpses=NMEA.ori(idx_NMEA_gps(idx_GPS,:));
            [ori_unique,~,ib]=unique(ori_gpses);
            ib_mode=mode(ib);
            if isnan(ib_mode)
                ori_mode='';
            else
                ori_mode=ori_unique(ib_mode);
            end
            
            idx_NMEA_gps=find((idx_NMEA_gps(idx_GPS,:)&strcmpi(NMEA.ori,ori_mode)));
            idx_NMEA_att=find(ismember(NMEA.type,NMEA_att));
            
            
            [gps_data_tmp,attitude_full,time_diff]=nmea_to_attitude_gps_v2(NMEA.string,NMEA.time,union(idx_NMEA_att,idx_NMEA_gps));
            
            time_str='';
            if time_diff>0
                time_str=sprintf('Computer time is %s in advance on GPS time',datestr(time_diff/(24*60*60),'HH:MM:SS'));
            elseif time_diff<0
                sprintf('Computer time is %s behind GPS time',datestr((-time_diff)/(24*60*60),'HH:MM:SS'));
            end
            if ~isempty(p.Results.load_bar_comp)
                p.Results.load_bar_comp.progress_bar.setText(time_str);
            else
                disp(time_str);
            end
            
            if isempty(attitude_full)
                if ~isempty(gps_data_tmp)
                    attitude_full=att_heading_from_gps(gps_data_tmp,2);
                end
            elseif all(isnan(attitude_full.Heading))
                if ~isempty(gps_data_tmp)
                    attitude_heading=att_heading_from_gps(gps_data_tmp,2);
                    attitude_full.Heading=resample_data_v2(attitude_heading.Heading,attitude_heading.Time,attitude_full.Time,'Type','Angle');
                    attitude_full.NMEA_heading=attitude_heading.NMEA_heading;
                end
            end
            
            gps_data=gps_data_tmp.clean_gps_track();
            %gps_data=gps_data_tmp;
            if isempty(attitude_full)||~any(attitude_full.Roll)&&~isempty(mru0_att.Roll)
                attitude_full=mru0_att;
            end
            
            new_lines=nmea_to_lines(NMEA,setdiff({'DFT','DBS','OFS'},NMEA_ignore));
            
            if ~isempty(new_lines)
                trans_depth=new_lines(1).Range;
                depth_time=new_lines(1).Time;
                new_lines(1).Tag='offset';
            else
                trans_depth=[];
                depth_time=[];
            end
            
            if GPSOnly(uu)==0
                for i =1:length(trans_obj)
                    if trans_obj(i).need_escorr()
                        es_offset=p.Results.EsOffset;
                        if (isempty(es_offset)||isnan(es_offset)||~isnumeric(es_offset))&&isfile(fullfile(path_f,'survey_options.xml'))
                            survey_options_obj=parse_survey_options_xml(fullfile(path_f,'survey_options.xml'));
                            es_offset = survey_options_obj.Es60_correction;
                        end
                        trans_obj(i).correctTriangleWave('EsOffset',es_offset,...
                            'load_bar_comp',p.Results.load_bar_comp);
                    end
                end
                if ~isempty(cal)
                    for n=1:length(trans_obj)
                        idx_cal=find(trans_obj(n).get_params_value('Frequency',1)==cal.F);
                        if ~isempty(idx_cal)
                            
                            tau = trans_obj(n).get_params_value('PulseLength',1);
                            idx = find(trans_obj(n).Config.PulseLength == tau);
                            
                            if (~isempty(idx))
                                trans_obj(n).Config.SaCorrection(idx)=cal.SACORRECT(idx_cal);
                                trans_obj(n).Config.Gain(idx)=cal.G0(idx_cal);
                            else
                                trans_obj(n).Config.SaCorrection=cal.SACORRECT(idx_cal).*ones(size(trans_obj(n).Config.SaCorrection));
                                trans_obj(n).Config.Gain=cal.G0(idx_cal).*ones(size(trans_obj(n).Config.SaCorrection));
                            end
                        end
                    end
                end
                
                vec_freq=nan(1,numel(trans_obj));
                for itrans=1:length(trans_obj)
                    vec_freq(itrans)=trans_obj(itrans).Config.Frequency;
                end
                
                
                for itrans=1:length(trans_obj)
                    
                    if~isempty(trans_depth)
                        [dt,idx]=nanmin(abs(depth_time(:)-trans_obj(itrans).Time(:)'));
                        idx_rem= dt>nanmax(10*mode(diff(trans_obj(itrans).Time)),5*mode(diff(depth_time)));
                        trans_depth_resampled=trans_depth(idx);
                        trans_depth_resampled(idx_rem)=0;
                        trans_obj(itrans).TransducerDepth=trans_depth_resampled;
                    else
                        trans_obj(itrans).TransducerDepth = zeros(size(trans_obj(itrans).Time));
                    end
                end
                
                if  ~isa(trans_obj,'transceiver_cl')
                    id_rem=union(id_rem,uu);
                    continue;
                end
                

                
                for i =1:length(trans_obj)
                    gps_data_ping=gps_data.resample_gps_data(trans_obj(i).Time);
                    attitude=attitude_full.resample_attitude_nav_data(trans_obj(i).Time);   
                    trans_obj(i).Params=trans_obj(i).Params.reduce_params();
                    trans_obj(i).GPSDataPing=gps_data_ping;
                    trans_obj(i).AttitudeNavPing=attitude;
                    trans_obj(i).set_pulse_Teff();
                    trans_obj(i).set_pulse_comp_Teff();
                end
            end
            
            layers(uu)=layer_cl('Filename',{Filename},'Filetype',ftype,'GPSData',gps_data,'AttitudeNav',attitude_full,'EnvData',envdata,...
                'AvailableFrequencies',av_frequencies,'AvailableChannelIDs',av_cids);
            
            config_file=fullfile(path_f,[fileN '_config.xml']);
            
            if isfile(config_file)
                try
                    fid=fopen(config_file,'r');
                    t_line=fread(fid,'*char');
                    t_line=t_line';
                    fclose(fid);
                    [~,output,type]=read_xml0(t_line);
                    switch type
                        case 'Configuration'
                            for i=1:length(trans_obj)
                                idx = find(strcmp(deblank( trans_obj(i).Config.ChannelID),deblank(cellfun(@(x) x.ChannelIdShort,output,'un',0))));
                                if ~isempty(idx)
                                    config_obj=config_obj_from_xml_struct(output(idx),t_line);
                                    if~isempty(config_obj)
                                        trans_obj(i).Config=config_obj;
                                    end
                                end
                            end
                    end
                catch
                    warndlg_perso([],'XML',sprintf('Could not read Config file for file %s\n',fileN),5)
                    
                end
            else
                if strcmpi(ftype,'ek80')
                    fid=fopen(config_file,'w+');
                    if fid>0
                        fwrite(fid,trans_obj(1).Config.XML_string,'char');
                        fclose(fid);
                    end
                end
            end
            
            layers(uu).add_trans(trans_obj);
            layers(uu).add_lines(new_lines);
            if p.Results.LoadEKbot>0
                layers(uu).load_ek_bot();
            end
        catch err
            id_rem=union(id_rem,uu);
            warndlg_perso([],'',sprintf('Could not open files %s\n',Filename));
            print_errors_and_warnings(1,'error',err);
            %             if ~isdeployed
            %                 rethrow(err);
            %             end
        end
        
        if ~isempty(load_bar_comp)
            set(load_bar_comp.progress_bar,'Value',uu);
        end
        
    end
    
    if length(id_rem)==length(layers)
        layers=layer_cl.empty();
    else
        layers(id_rem)=[];
    end
    
    clear('data','transceiver');
    
    %            profile off;
    %            profile viewer;
    
end