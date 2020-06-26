%% read TOPAS raw files
% Adapted from Tom Weber, July 2018
% Yoann Ladroit


function layers=read_topas(Filename_cell,varargin)

p = inputParser;

if ~iscell(Filename_cell)
    Filename_cell={Filename_cell};
end

[def_path_m,~,~]=fileparts(Filename_cell{1});

addRequired(p,'Filename_cell',@(x) ischar(x)||iscell(x));
addParameter(p,'PathToMemmap',def_path_m,@ischar);
addParameter(p,'load_bar_comp',[]);

parse(p,Filename_cell,varargin{:});


dir_data=p.Results.PathToMemmap;
enc='ieee-be';
nb_files=length(Filename_cell);
load_bar_comp=p.Results.load_bar_comp;

for i_cell=1:length(Filename_cell)
    
    Filename=Filename_cell{i_cell};
    
    str_disp=sprintf('Opening File %d/%d : %s',i_cell,nb_files,Filename);
    if ~isempty(load_bar_comp)
        set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',nb_files,'Value',i_cell-1);
        load_bar_comp.progress_bar.setText(str_disp);
    else
        disp(str_disp)
    end
    
    fid=fopen(Filename,'r',enc);
    
    if fid==-1
        continue;
    end
    
    pidx = 0;
    while ~feof(fid)
        try
            pidx = pidx + 1;
            data.PingNumber(pidx) = fread(fid,1,'int16','b');
            data.TOPASformat(pidx) = fread(fid,1,'int16','b');
            yr = fread(fid,1,'int16','b');
            mo = fread(fid,1,'int16','b');
            dy = fread(fid,1,'int16','b');
            hr = fread(fid,1,'int16','b');
            mi = fread(fid,1,'int16','b');
            sc = fread(fid,1,'int16','b');
            msc = fread(fid,1,'int16','b');
            
            data.pingTime(pidx) = datenum(yr,mo,dy,hr,mi,sc+msc/1000);
            data.origFilename{pidx} = fread(fid,16,'*char')';
            data.lineId{pidx} = fread(fid,18,'*char')';
            data.project{pidx} = fread(fid,20,'*char')';
            data.channel_number(pidx) = fread(fid,1,'int16','b');   %
            data.TxLevel(pidx) = fread(fid,1,'float','b'); % Transmitter amplitude level in dB relative max output (0 to -30 dB)
            data.PingInterval(pidx) = fread(fid,1,'float','b'); % in milliseconds
            data.pulseform(pidx) = fread(fid,1,'int16','b');   % 0 no output, 1=CW,2=Ricker; 3=Chirp(LFM); 7=Chirp(HFM); 4=upload; 5=download
            data.attitudeCompensation(pidx) = fread(fid,1,'int16','b');    % 1 on, 0 off
            data.CentreFreq(pidx) = fread(fid,1,'float','b');              % center frequency in Hz
            data.ChirpStart(pidx) = fread(fid,1,'float','b');
            data.ChirpStop(pidx) = fread(fid,1,'float','b');
            data.ChirpLength(pidx) = fread(fid,1,'float','b');     % milliseconds
            data.MatchFiltered(pidx) = fread(fid,1,'int16','b');   % 0/1(pidx) = not match filtered; 2(pidx) = match filtered/spiking deconvolution
            data.beamPointingDirAlong(pidx) = fread(fid,1,'float','b'); % beam pointing direction alongship (+/-10 deg relative to vertical, positive value is forward
            data.scan_sec_along(pidx) = fread(fid,1,'float','b');  % beam scanning sector alongship (0-20 degrees)
            data.scan_step_along(pidx) = fread(fid,1,'float','b'); % beam step size alongship (0-10 degrees)
            data.beamPointingDirAthw(pidx) = fread(fid,1,'float','b'); % beam pointing direction athwartship (+/-40 deg relative to vertical, positive value is toward port)
            data.scan_sec_athw(pidx) = fread(fid,1,'float','b');   % beam scanning sector athwartship, 0-80 deg
            data.scan_step_athw(pidx) = fread(fid,1,'float','b');  % beam step size athwartship, 0-10 deg
            data.lat_north(pidx) = fread(fid,1,'float64','b')/100;
            data.lon_east(pidx) = fread(fid,1,'float64','b')/100;
            data.zone_lon(pidx) = fread(fid,1,'float64','b');
            data.heading(pidx) = fread(fid,1,'float','b');         % degrees
            data.speed(pidx) = fread(fid,1,'float','b');           % m/s
            data.coordSys(pidx) = fread(fid,1,'int16','b');        % 0 is geo coord, 1(pidx) = utm
            data.utmzone(pidx) = fread(fid,1,'int16','b');
            data.depth(pidx) = fread(fid,1,'float','b');           % depth from transducer to seabed, m
            data.tx_heave(pidx) = fread(fid,1,'float','b');        % m
            data.tx_roll(pidx) = fread(fid,1,'float','b');         % deg
            data.tx_pitch(pidx) = fread(fid,1,'float','b');        % deg
            data.rx_heave(pidx) = fread(fid,1,'float','b');        % m
            data.rx_roll(pidx) = fread(fid,1,'float','b');         % deg
            data.rx_pitch(pidx) = fread(fid,1,'float','b');        % deg
            data.triggerDelay(pidx) = fread(fid,1,'float','b');    % trigger delay from transmission to start acquisition, ms
            data.traceDuration(pidx) = fread(fid,1,'float','b');   % ms
            data.sampFreq(pidx) = fread(fid,1,'float','b');        % sampling frequency in Hz
            data.userAdjustableGain(pidx) = fread(fid,1,'float','b');  % 0-72 dB
            data.baseband(pidx) = fread(fid,1,'int16','b');         % 0(pidx) = normal, 1(pidx) = baseband
            data.hpFilter(pidx) = fread(fid,1,'float','b');         % front end filter setting, kHz
            data.lp_filter(pidx) = fread(fid,1,'float','b');        % front end filter setting, kHz
            data.rollDir(pidx) = fread(fid,1,'float','b');          % instantaneous tx beam direction, roll (deg relative vertical; positive for port side up
            data.pitchDir(pidx) = fread(fid,1,'float','b');          % instantaneous tx beam direction, roll (deg relative vertical; positive for port side up
            data.transducerDraft(pidx) = fread(fid,1,'float','b');      % m
            data.beamWidthTx(pidx) = fread(fid,1,'int16','b');         % dummy, used by SBP120
            data.beamWidthRx(pidx) = fread(fid,1,'int16','b');         % dummy, used by SBP120
            data.beamNumber(pidx) = fread(fid,1,'int16','b');          % dummy, used by SBP120
            data.numberofbeams(pidx) = fread(fid,1,'short','b');       % dummy, used by SBP120
            data.pulseshape(pidx) = fread(fid,1,'int16','b');          % dummy, used by SBP120
            data.soundSpeed(pidx) = fread(fid,1,'float','b');          % used in depth calculations, m/s
            data.pingNumberSurvey(pidx) = fread(fid,1,'int32','b');    % ping number in survey, reset when new survey name
            data.pingNumberLine(pidx) = fread(fid,1,'int32','b');      % ping number in Line, reset when new line
            data.pingNumber(pidx) = fread(fid,1,'int32','b');          % used by SBP
            data.RxSensitivity(pidx) = fread(fid,1,'float','b');
            data.sourceLevel(pidx) = fread(fid,1,'float','b');
            data.externalDelay(pidx) = fread(fid,1,'int16','b');        % external delay from CODA nav string
            data.evenMarkCounter(pidx) = fread(fid,1,'int32','b');
            data.KP(pidx) = fread(fid,1,'float','b');                 % kiliometer point (CODA)
            notUsed = fread(fid,49,'int16','b');
            traceSize = fread(fid,1,'int32','b');
            traceSize2 = fread(fid,1,'int16','b');
            
            if traceSize == 0
                traceSize = traceSize2;
            end
            
            if traceSize<0
                pidx=pidx-1;
                continue;
            end
            
            if data.MatchFiltered(pidx)<2
                data.trace{pidx} = fread(fid,traceSize,'float','b');
                [B,A] = butter(7,[data.ChirpStart(pidx)/data.sampFreq(pidx) data.ChirpStop(pidx)/data.sampFreq(pidx)]);
                data.trace{pidx}=filter(B,A,data.trace{pidx});
                data.traceMF{pidx} =match_filter_topas(data.trace{pidx},data.ChirpStart(pidx),data.ChirpStop(pidx),data.sampFreq(pidx),data.ChirpLength(pidx)/1e3);
            else
                data.traceMF{pidx} = fread(fid,traceSize,'float','b');
                data.trace{pidx}=data.traceMF{pidx};
            end
            notUsed = fread(fid,3,'int16','b');
            
        catch err
            disp('Issues reading trace');
            continue;
        end
    end
    
    fclose(fid);
    
    if pidx<=1
        layers=[];
        return;
    end
    
    data.nb_channel=unique(data.channel_number);
    
    transceiver(data.nb_channel)=transceiver_cl();
    att=attitude_nav_cl('Heading',zeros(size(data.pingTime)),'Pitch',data.tx_pitch,'Roll',data.tx_roll,'Heave',data.tx_heave,'Time',data.pingTime);
    gps_obj=gps_data_cl('Lat',data.lat_north,'Long',data.lon_east,'Time',data.pingTime);
    for ic=1:max(data.nb_channel)
        
        
        idx_channel=find(data.channel_number==data.channel_number(ic));
        if numel(unique(data.sampFreq(idx_channel)))>1
            warning('Sampling frequency changed during acquisition, not to be trusted...')
        end
        
        nb_samples_recorded=cellfun(@numel,data.trace(idx_channel));
        nb_samples_delays=ceil(data.triggerDelay(idx_channel).*data.sampFreq(idx_channel))/1e3;
        
        nb_samples_vec=nb_samples_recorded+nb_samples_delays;
        
        nb_samples=nanmax(nb_samples_vec);
        
        nb_pings=numel(idx_channel);
        nb_samples=nanmax(nb_samples);
        
        sample_number=(1:nb_samples)';
        c=data.soundSpeed(idx_channel(1));
        time=sample_number/data.sampFreq(idx_channel(1));
        range=c*time/2;
        
        
        config_obj=config_cl();
        config_obj.ChannelID=sprintf('TOPAS %.0fkHz',num2str(nanmean(data.CentreFreq(idx_channel))));
        params_obj=params_cl(nb_pings);
        envdata=env_data_cl('SoundSpeed',c);
        config_obj.EthernetAddress='';
        config_obj.IPAddress='';
        config_obj.SerialNumber='';
        
        
        config_obj.PulseLength=nanmean(data.ChirpLength(idx_channel));
        config_obj.BeamType=0;
        config_obj.BeamWidthAlongship=6;
        config_obj.BeamWidthAthwartship=6;
        config_obj.EquivalentBeamAngle=-21;
        config_obj.Frequency=nanmean(data.CentreFreq(idx_channel));
        config_obj.FrequencyMaximum=nanmax(data.ChirpStop(idx_channel));
        config_obj.FrequencyMinimum=nanmin(data.ChirpStart(idx_channel));
        config_obj.Gain=0;
        config_obj.SaCorrection=0;
        config_obj.TransducerName='TOPAS';
        config_obj.TransceiverName='TOPAS';
        
        params_obj.Time=data.pingTime(idx_channel);
        params_obj.Frequency(:)=data.CentreFreq(idx_channel);
        params_obj.FrequencyEnd(:)=data.ChirpStop(idx_channel);
        params_obj.FrequencyStart(:)=data.ChirpStart(idx_channel);
        params_obj.PulseLength(:)=nanmean(data.ChirpLength(idx_channel))/1e3;
        params_obj.SampleInterval(:)=1./data.sampFreq(idx_channel);
        params_obj.TransmitPower(:)=data.sourceLevel(idx_channel);
        params_obj.Absorption(:)= seawater_absorption((params_obj.FrequencyStart+params_obj.FrequencyEnd(1))/2/1e3, (envdata.Salinity), (envdata.Temperature), (envdata.Depth),'fandg')/1e3;
        
        power_lin=zeros(nb_samples,nb_pings);
        
        for ip=1:nb_pings
            power_lin(nb_samples_delays(ip)+1:nb_samples_delays(ip)+nb_samples_recorded(ip),ip)=data.traceMF{idx_channel(ip)};
        end
        
        data_struct.y_real = real(power_lin);
        data_struct.y_imag = imag(power_lin);
        data_struct.power = (abs(power_lin));
        
        [sub_ac_data_temp,curr_name]=sub_ac_data_cl.sub_ac_data_from_struct(data_struct,dir_data,{});
        
        
        ac_data_temp=ac_data_cl('SubData',sub_ac_data_temp,...
            'Nb_samples',length(range),...
            'Nb_pings',nb_pings,...
            'MemapName',curr_name);
        
       
        
        lat=data.lat_north(idx_channel);
        lon=data.lon_east(idx_channel);
        
        lat_deg=sign(lat).*round(abs(lat));
        lat_min=sign(lat).*(abs(lat)-abs(lat_deg))*100/60;
        
        lon_deg=sign(lon).*round(abs(lon));
        lon_min=sign(lon).*(abs(lon)-abs(lon_deg))*100/60;
        
        att_chan=attitude_nav_cl('Heading',zeros(size(data.pingTime(idx_channel))),'Pitch',data.tx_pitch(idx_channel),'Roll',data.tx_roll(idx_channel),'Heave',data.tx_heave(idx_channel),'Time',data.pingTime(idx_channel));
        gps_chan=gps_data_cl('Lat',lat_deg+lat_min,'Long',lon_deg+lon_min,'Time',data.pingTime(idx_channel));
        transceiver(ic)=transceiver_cl('Data',ac_data_temp,...
            'AttitudeNavPing',att_chan,...
            'GPSDataPing',gps_chan,...
            'Range',range,...
            'Time',data.pingTime(idx_channel),...
            'TransducerDepth',data.transducerDraft(idx_channel),...
            'Mode','FM',...
            'Config',config_obj,...
            'Params',params_obj);
        transceiver(ic).set_absorption(envdata);
    end
    layers(i_cell)=layer_cl('Filename',{Filename},'Filetype','TOPAS','Transceivers',transceiver,'EnvData',envdata,'AttitudeNav',att,'GPSData',gps_obj);
    
    
end
end


function mf_data=match_filter_topas(data,sf,ef,samp_freq,pulse_len)

traceH = hilbert(data);
t = (1/samp_freq):(1/samp_freq):(pulse_len);
mf = hilbert(chirp(t,sf,pulse_len,ef));
mf = mf/max(conv(mf,fliplr(conj(mf))));
mf = mf.*tukeywin(length(mf),.25)';

traceMF = conv(traceH,fliplr(conj(mf)));
mf_data = (traceMF(ceil(length(mf/2)):end));


end


