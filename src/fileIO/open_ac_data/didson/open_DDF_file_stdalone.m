function [layers,id_rem] = open_DDF_file_stdalone(Filename_cell,varargin)

p = inputParser;

id_rem = [];
layers = layer_cl.empty();

if ~iscell(Filename_cell)
    Filename_cell = {Filename_cell};
end

if ~iscell(Filename_cell)
    Filename_cell = {Filename_cell};
end

if isempty(Filename_cell)
    return;
end

[def_path_m,~,~] = fileparts(Filename_cell{1});

addRequired(p,'Filename_cell',@(x) ischar(x)||iscell(x));
addParameter(p,'PathToMemmap',def_path_m,@ischar);
addParameter(p,'load_bar_comp',[]);

parse(p,Filename_cell,varargin{:});

load_bar_comp = p.Results.load_bar_comp;

c=1500;
envdata=env_data_cl('SoundSpeed',c);

if ~isequal(Filename_cell, 0)
    
    nb_files = numel(Filename_cell);
    if ~isempty(load_bar_comp)
        set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',length(Filename_cell),'Value',0);
    end
    layers(length(Filename_cell)) = layer_cl();
    id_rem = [];
    
    %     f=figure();
    %     ax = axes(f);
    %     imh = imagesc(ax,0);
    for uu = 1:nb_files
        
        if ~isempty(load_bar_comp)
            str_disp=sprintf('Opening File %d/%d : %s',uu,nb_files,Filename_cell{uu});
            load_bar_comp.progress_bar.setText(str_disp);
        end
        
        Filename = Filename_cell{uu};
        if ~isfile(Filename)
            id_rem = union(id_rem,uu);
            continue;
        end
        
        %[path_f,fileN,~] = fileparts(Filename);
        
        fid=fopen(Filename,'rb');
        
        
        if fid==-1
            id_rem = union(id_rem,uu);
            continue;
        end
        ddf_str = fread(fid,3,'*char')';
        
        if ~strcmpi(ddf_str,'ddf')
            fclose(fid);
            id_rem = union(id_rem,uu);
            continue;
        end
        
        ddf_ver = fread(fid,1,'int8');
        fileheader=get_file_header(fid,ddf_ver);
        
        [~,curr_filename,~]=fileparts(tempname);
        curr_data_name_t=fullfile(p.Results.PathToMemmap,curr_filename);
        params_obj = params_cl(1,fileheader.numbeams);
        time_f = nan(1,fileheader.numframes);
        config_obj = config_cl();
        config_obj.SerialNumber = num2str(fileheader.serialnumber);
        config_obj.ChannelID = sprintf('DIDSON_%d',fileheader.serialnumber);
        config_obj.TransceiverName= sprintf('DIDSON_%d',fileheader.serialnumber);
        config_obj.TransducerName= sprintf('DIDSON_%d',fileheader.serialnumber);
        config_obj.ChannelNumber = 1;
  
        if fileheader.resolution == 0
            config_obj.Frequency = 1.1*1e6;
            config_obj.BeamWidthAlongship = 14;
            config_obj.BeamWidthAthwartship = 0.4;
            beamspacing = 0.6;
        else
            config_obj.Frequency = 1.8*1e6;
            config_obj.BeamWidthAlongship = 14;
            config_obj.BeamWidthAthwartship = 0.3;
            beamspacing = 0.3;
        end
        
        config_obj.FrequencyMaximum = 2.2*1e6;
        config_obj.FrequencyMinimum = 1.1*1e6;
        config_obj.Gain = fileheader.receivergain/2;
        

        ac_data_temp = ac_data_cl('SubData',[],...
            'Nb_samples', fileheader.samplesperchannel,...
            'Nb_pings',   fileheader.numframes,...
            'Nb_beams',   fileheader.numbeams,...
            'MemapName',  curr_data_name_t);
        
        ac_data_temp.init_sub_data('img_intensity',0);
        iframe = 0;
        
               
        while ~feof(fid) && iframe < fileheader.numframes
            
            if ~isempty(load_bar_comp)
                set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',fileheader.numframes,'Value',iframe);
            end
            try
                frameheader=get_frame_header(fid,ddf_ver,fileheader.serialnumber,fileheader.resolution);
            catch err
                fprintf('Could not read frame %d\n',iframe+1);
            end
            
            iframe = frameheader.framenumber+1;
            if iframe ==1
                params_obj.BeamAngleAlongship(:,iframe)=zeros(1,fileheader.numbeams);
                params_obj.BeamAngleAthwartship(:,iframe)=((fileheader.numbeams-1)*beamspacing)*linspace(-1/2,1/2,fileheader.numbeams);
                params_obj.PulseLength(:,iframe)=double(frameheader.pulselength);
                params_obj.SampleInterval(:,iframe)=1/double(fileheader.samplerate);
                params_obj.TransmitPower(:,iframe)=1e3;
                params_obj.Frequency(:,iframe) = config_obj.Frequency;
                params_obj.FrequencyStart(:,iframe) = config_obj.Frequency;
                params_obj.FrequencyEnd(:,iframe) = config_obj.Frequency;
            end
            %params_obj.BeamAngle(:,iframe) = ((fileheader.numbeams-1)*beamspacing/2)*linspace(-1/2,1/2,fileheader.numbeams);

            t=frameheader.ymdHMSF(1:6)';
            t(6)=t(6)+frameheader.ymdHMSF(7)/1e3;
            time_f(iframe) = datenum(t);
%             switch frameheader.configflags
%                 case 0
%                     data.configuration ='DIDSON-S Extended Windows';
%                 case 1
%                     data.configuration ='DIDSON-S Classic Windows';
%                 case 2
%                     data.configuration ='DIDSON-LR Extended Windows';
%                 case 3
%                     data.configuration ='DIDSON-LR Classic Windows';
%             end
            
            frame=fread(fid,[fileheader.numbeams,fileheader.samplesperchannel],'uint8');
            
            if fileheader.reverse == 0
                frame=fliplr(frame'); %Transposed and flipped data frame assumes uninverted sonar
            else
                frame=frame'; % Assume inverted sonar
            end

            ac_data_temp.replace_sub_data_v2(frame,'idx_ping',iframe,'field','img_intensity');
            %ac_data_temp.replace_sub_data_v2(db2pow(frame),'idx_ping',iframe,'field','power');
            
        end
        
        fclose(fid);

        trans_obj=transceiver_cl('Data',ac_data_temp,...
            'Range',frameheader.windowstart+c*(0:fileheader.samplesperchannel-1)'/fileheader.samplerate/2,...
            'Time',time_f,...
            'Config',config_obj,...
            'Mode','CW',...
            'Params',params_obj);
        
        trans_obj.set_absorption(envdata);

        layers(uu)=layer_cl('Filename',{Filename},'Filetype','DIDSON','Transceivers',trans_obj,'EnvData',envdata);
        if ~isempty(load_bar_comp) 
            set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',length(Filename_cell),'Value',uu);
        end
    end
    
    
    if length(id_rem)==length(layers)
        layers=layer_cl.empty();
    else
        layers(id_rem)=[];
    end
    
    
end
end

function header = get_file_header(fid,ver)

header.userassigned = '';
header.numframes=fread(fid,1,'int32');
header.framerate=fread(fid,1,'int32');
header.resolution=fread(fid,1,'int32'); % 0=lo 1 = Hi
header.numbeams=fread(fid,1,'int32'); %48 Lo 96 Hi for standard mode
if ver >=2
    header.numbeams=48 + 48*(header.resolution == 1);
end

header.samplerate=fread(fid,1,'float32');
header.samplesperchannel=fread(fid,1,'int32');
header.receivergain=fread(fid,1,'int32'); %0-40 dB

header.windowstart = fread(fid,1,'int32');  %Windowstart 1 to 31

header.windowlength =fread(fid,1,'int32'); %Windowlength coded as 0 to 3
if ver>=1
    header.reverse=fread(fid,1,'int32');
    header.serialnumber=fread(fid,1,'int32');
else
    header.reverse=0;
    header.serialnumber=0;
end

if ver==0
    length1=fread(fid,1,'uchar');
    header.date=fread(fid,length1,'*char')';
    length2=fread(fid,1,'uchar');
    header.idstring=fread(fid,length2,'*char')';
    header.id1 = 0;
    header.id2 = 0;
    header.id3 = 0;
    header.id4 = 0;
else
    header.date = fread(fid,32,'*char')'; %date file was made
    header.idstring = fread(fid,256,'*char')'; %User supplied identification notes
    header.id1 = fread(fid,1,'int32'); %four user supplied integers
    header.id2 = fread(fid,1,'int32');
    header.id3 = fread(fid,1,'int32');
    header.id4 = fread(fid,1,'int32');
end

if ver >=2
    header.startframe = fread(fid,1,'int32'); %used if this is a snippet file from source file
    header.endframe = fread(fid,1,'int32'); %Used if this is a snippet file from source file
    if ver ==2
        header.userassigned = fread(fid,152,'*char')'; %User assigned space
    end
else
    header.startframe = 0;
    header.endframe = 0;
end

if ver >=3
    header.timelapse = fread(fid,1,'int32'); %Logic 0 or 1 (1 = timelapse active);
    header.recordInterval = fread(fid,1,'int32');
    header.radioseconds = fread(fid,1,'int32');
    header.frameinterval= fread(fid,1,'int32');
else
    header.timelapse = 0;
    header.recordInterval = 0;
    header.radioseconds = 0;
    header.frameinterval= 0;
end

if ver ==3
    header.userassigned = fread(fid,136,'*char')';
elseif ver ==4
    header.userassigned = fread(fid,648,'*char')';
end



end

function header = get_frame_header(fid,ver,serialnumber,resolution)


header.configflags = 1;
header.framenumber =fread(fid,1,'int32');

if ver>=3
    header.frametime   =fread(fid,2,'int32');
else
    header.frametime   =fread(fid,1,'int32');
end

header.version     =fread(fid,4,'*char')';
header.status      =fread(fid,1,'int32');

header.ymdHMSF     =fread(fid,7,'int32');

header.transmit    =fread(fid,1,'int32'); % 0= on  1 = off
%Windowstart 1 to 31 times 0.75 (lo) or 0.375 (hi)
header.windowstart = fread(fid,1,'int32');
index=fread(fid,1,'int32') +1 +2*(resolution == 0);

if(index > 5)  %put in because shipwreck has incorrect file header
    index = 5;  % This means windowlengths of 36 meters will not be recognized
end

tmp                =fread(fid,8,'int32');

header.threshold   =tmp(1);
header.intensity   =tmp(2);
header.receivergain=tmp(3);
header.degc1       =tmp(4);
header.degc2       =tmp(5);
header.humidity    =tmp(6);
header.focus       =tmp(7);
header.battery     =tmp(8);

header.status1     =fread(fid,16,'*char')';
header.status2     =fread(fid,16,'*char')';

if ver >=2
    tmp                =fread(fid,12,'float32');
    header.velocity    =tmp(1);
    header.depth       =tmp(2);
    header.altitude    =tmp(3);
    header.pitch       =tmp(4);
    header.pitchrate   =tmp(5);
    header.roll        =tmp(6);
    header.rollrate    =tmp(7);
    header.heading     =tmp(8);
    header.headingrate =tmp(9);
    header.sonarpan    =tmp(10);
    header.sonartilt   =tmp(11);  % Read from compass if used, Read from Pan/Tilt if used and no compass
    header.sonarroll   =tmp(12);  % Read from compass if used, Read from Pan/Tilt if used and no compass
    pos                =fread(fid,2,'float64');
    header.latitude    =pos(1);
    header.longitude   =pos(2);
    if ver ==2
        header.userassigned=fread(fid,76,'*char')';
    end
else
    header.velocity    =0;
    header.depth       =0;
    header.altitude    =0;
    header.pitch       =0;
    header.pitchrate   =0;
    header.roll        =0;
    header.rollrate    =0;
    header.heading     =0;
    header.headingrate =0;
    header.sonarpan    =0;
    header.sonartilt   =0;
    header.sonarroll   =0;
    header.latitude    =0;
    header.longitude   =0;
end

if ver >=3
    
    header.sonarposition =fread(fid,1,'float32');
    
    if ver ==3
        header.configflags =bitand(fread(fid,1,'int32'),3); % bit0: 1=classic, 0=extended windows; bit1: 0=Standard, 1=LR
        header.userassigned=fread(fid,60,'*char')';  %Free space for user
    elseif ver ==4
        header.configflags =bitand(fread(fid,1,'int32'),3); % bit0: 1=classic, 0=extended windows; bit1: 0=Standard, 1=LR
        header.userassigned=fread(fid,828,'*char')';  %Move pointer to end of frame header of length 1024 bytes
    end
    
    
    if (serialnumber < 19)   %Special Case 1
        header.configflags = 1;
    end
    
    if (serialnumber == 15)  %Special Case 2
        header.configflags = 3;
    end
end

switch header.configflags %
    case 0
        winlengths   = [1.25 2.5 5 10 20 40];      % DIDSON-S, Extended Windows
        pulselengths = [4.5 9 18 36 72 144]*1e-6;   %not sure
    case 1
        winlengths    = [1.125 2.25 4.5 9 18 36];   % DIDSON-S, Classic Windows
        pulselengths = [4.5 9 18 36 72 144]*1e-6;   %not sure
    case 2
        winlengths   = [2.5 5 10 20 40 70];        % DIDSON-LR, Extended Windows
        pulselengths = [9 18 36 72 144 288]*1e-6;   %not sure
    case 3
        winlengths   = [2.25 4.5 9 18 36 72];      % DIDSON-LR, Classic Windows
        pulselengths = [9 18 36 72 144 288]*1e-6; %not sure
end


%Windowstart 1 to 31 times 0.75 (lo) or 0.375 (hi) or 0.419 for extended
switch header.configflags
    case {1,3}
        header.windowstart = header.windowstart*(0.375 +(resolution == 0)*0.375); %meters for standard or long range DIDSON
    case {0,2}
        header.windowstart = header.windowstart*(0.419 +(resolution == 0)*0.419); %meters for extended DIDSON
end

header.windowlength = winlengths(index);   % Convert windowlength code to meters
header.pulselength = pulselengths(index);   

end



