function  layers=open_FCV30_file_stdalone_v2(file_lst,varargin)

p = inputParser;

[def_path_m,~,~]=fileparts(file_lst);

addRequired(p,'file_lst',@(x) ischar(x)||iscell(x));
addParameter(p,'PathToMemmap',def_path_m,@ischar);
addParameter(p,'Calibration',[]);
addParameter(p,'Frequencies',[]);
addParameter(p,'FieldNames',{});
addParameter(p,'GPSOnly',0);
addParameter(p,'load_bar_comp',[]);
addParameter(p,'file_idx',[]);
addParameter(p,'block_len',get_block_len(100,'cpu'),@(x) x>0);

parse(p,file_lst,varargin{:});

[main_path,~,~]=fileparts(file_lst);
load_bar_comp=p.Results.load_bar_comp;

[path_to_data,fname,ext]=fileparts(file_lst);
switch ext
    case '.lst'
        list_files=importdata(file_lst);
        %[folder_lst,~,~]=fileparts(file_lst);
        filename_dat_tot=cell(1,length(list_files));
        filename_ini=cell(1,length(list_files));
        
        for i=1:length(list_files)
            str_temp=strsplit(list_files{i},',');
            filename_dat_tot{i}=fullfile(main_path,str_temp{1});
            filename_ini{i}=fullfile(main_path,str_temp{2});
        end
        fidx=p.Results.file_idx;
        
    case '.ini'
        list_ini=dir(fullfile(path_to_data,'*.ini'));
        list_ini([list_ini(:).isdir]==1)=[];
        list_ini_t=[list_ini.datenum];
        list_dat=dir(fullfile(path_to_data,'*.dat'));
        list_dat([list_dat(:).isdir]==1)=[];
        list_dat_t=[list_dat.datenum];
        
        [~,idx_order]=sort(list_dat_t);
        list_dat=list_dat(idx_order);
        
        [~,idx_order]=sort(list_ini_t);
        list_ini=list_ini(idx_order);
        
        list_ini_name={list_ini.name};
        list_dat_name={list_dat.name};
        
        list_ini_time=[list_ini.datenum];
        list_dat_time=[list_dat.datenum];
        
        tf_ini=cellfun(@(x) textscan(x,'%2d_%2d_%2d_%3d.ini'),list_ini_name,'un',0);
        
        tf_dat=cellfun(@(x) textscan(x,'%2d_%2d_%2d_%3d.dat'),list_dat_name,'un',0);
        
        filename_ini=cell(1,length(list_ini_t));
        idx_keep_tot=true(1,numel(tf_dat));
        
        for ii=1:numel(list_ini_name)-1
            idx_keep=cellfun(@(x) sum(double(cell2mat(tf_ini{ii}(:))).*[1e3;1e2;1e1;0.1])<=sum(double(cell2mat(x(:))).*[1e3;1e2;1e1;0.1])&...
                sum(double(cell2mat(tf_ini{ii+1}(:))).*[1e3;1e2;1e1;0.1])>sum(double(cell2mat(x(:))).*[1e3;1e2;1e1;0.1]),tf_dat,'un',1);
            filename_ini(idx_keep)=list_ini_name(ii);
            idx_keep_tot(idx_keep)=false;
        end
        
        filename_ini(idx_keep_tot)=list_ini_name(end);
        
        filename_ini=fullfile(path_to_data,filename_ini);
        filename_dat_tot=fullfile(path_to_data,list_dat_name);
        [ini_config_files,~,~]=unique(filename_ini);
        fidx=find(strcmpi(file_lst,ini_config_files));
end

[ini_config_files,~,id_config_unique]=unique(filename_ini);

%file_mat_ini=cellfun(@(x) fullfile(folder_lst,'echoanalysisfiles',[x '.mat']),fname_ini_mat,'UniformOutput',0);

id_config=(1:length(ini_config_files));

if ~isempty(fidx)
    id_config=fidx;
end
G=20;
SL=30;
ME=0;
c=1500;
alpha=9/1000;
L0=0.152;

[fields,~,fmt_fields,factor_fields]=init_fields();

nb_config=length(id_config);

layers(nb_config)=layer_cl();
ilay=0;



for iconfig=id_config
    ilay=ilay+1;
    str_disp=sprintf('Opening File %d/%d',ilay,length(id_config));
    if ~isempty(load_bar_comp)
        set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',length(id_config),'Value',ilay-1);
        load_bar_comp.progress_bar.setText(str_disp);
    else
        disp(str_disp)
    end
    
    filename_dat=filename_dat_tot(id_config_unique==iconfig);
    nb_pings_tot=length(filename_dat);
    
    
    params_current=params_cl(nb_pings_tot);
    config_current=config_cl();
    
    if ~isempty(load_bar_comp)
        set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',nb_pings_tot, 'Value',0);
    end
    idx_pings_tot=1:nb_pings_tot;
    nb_samples_max=5*1e4;
    
    block_size=nanmin(ceil(p.Results.block_len/nb_samples_max),numel(idx_pings_tot));
    
    num_ite=ceil(numel(idx_pings_tot)/block_size);
    
    
    
    idx_fields=ismember(fields,{'power' 'alongangle','acrossangle'});
    
    fields=fields(idx_fields);
    fmt_fields=fmt_fields(idx_fields);
    factor_fields=factor_fields(idx_fields);
    
    curr_data_name=cell(1,numel(fields));
    
    fileID=-ones(1,numel(fields));
    [~,curr_filename,~]=fileparts(tempname);
    curr_data_name_t=fullfile(p.Results.PathToMemmap,curr_filename);
    
    for ifif=1:numel(fields)
        curr_data_name{ifif}=[curr_data_name_t fields{ifif} '.bin'];
        fileID(ifif) = fopen(curr_data_name{ifif},'w');
    end
    
    
    for ui=1:num_ite
        idx_pings=idx_pings_tot((ui-1)*block_size+1:nanmin(ui*block_size,numel(idx_pings_tot)));
        
        nb_pings=numel(idx_pings);
        
        
        for u=1:nb_pings
            ip=idx_pings(u);
            if ~isempty(load_bar_comp)
                str_disp=sprintf('Getting infos for file %s',filename_dat{ip});
                set(load_bar_comp.progress_bar, 'Value',ip);
                load_bar_comp.progress_bar.setText(str_disp);
            end
            
            fid=fopen(filename_dat{ip},'r','n');
            
            header.Model=fread(fid,8,'*char')';
            header.Fmt_ver=fread(fid,1,'ushort')';
            header.Date=nan(1,6);
            header.Date(1)=fread(fid,1,'short')';
            header.Date(2)=fread(fid,1,'short')';
            header.Date(3)=fread(fid,1,'short')';
            header.Date(4)=fread(fid,1,'short')';
            header.Date(5)=fread(fid,1,'short')';
            header.Date(6)=fread(fid,1,'short')';
            header.Remarks=char(fread(fid,287,'short')');
            
            params.Time(ip)=datenum(header.Date);
            params.Mode(ip)=fread(fid,1,'short');
            params.TotalBeamNumber(ip)=fread(fid,1,'short');
            params.Beam_Id(ip,:)=fread(fid,5,'short');
            params.Range(ip)=fread(fid,1,'short');
            params.Frequency(ip)=fread(fid,1,'short')*10;
            params.BearingAngle(ip,:)=fread(fid,6,'short')*1e-1;
            params.TiltAngle(ip,:)=fread(fid,6,'short')*1e-1;
            params.TXfrequency(ip,:)=fread(fid,6,'short')*10;
            params.TXpower(ip,:)=fread(fid,6,'short');
            params.ChirpWidth(ip,:)=fread(fid,6,'short')*10;
            params.TXcycle(ip)=fread(fid,1,'short')*1e-3;
            params.TXPulseWidth(ip,:)=fread(fid,6,'short')*1e-6;
            params.EnvelopeEdgeWidth(ip,:)=fread(fid,6,'short')*1e-6;
            params.Remarks1{ip}=char(fread(fid,357,'short')');
            params.TXroll(ip)=fread(fid,1,'short')*1e-1;
            params.TXpitch(ip)=fread(fid,1,'short')*1e-1;
            params.RXroll(ip)=fread(fid,1,'short')*1e-1;
            params.RXpitch(ip)=fread(fid,1,'short')*1e-1;
            params.Remarks2{ip}=char(fread(fid,313,'short')');
            
            
            NMEA.UTC(ip)=fread(fid,1,'ulong')/(24*60*60)+datenum('1980/01/06 00:00:00','yyyy/mm/dd HH:MM:SS');
            NMEA.Latitude(ip)=fread(fid,1,'long')*1e-4/60;
            NMEA.Longitude(ip)=fread(fid,1,'long')*1e-4/60;
            NMEA.Status(ip)=fread(fid,1,'short');
            NMEA.speed(ip)=fread(fid,1,'short')*1e-2;%knots
            NMEA.Heading(ip)=fread(fid,1,'short')*1e-1;
            NMEA.VesselCourse(ip)=fread(fid,1,'short')*1e-1;
            NMEA.WaterTemperature(ip)=fread(fid,1,'short')*1e-2;%deg C
            NMEA.Remarks{ip}=char(fread(fid,117,'short')');
            
            fread(fid,768,'int8');
            
            att.DataNumber(ip)=fread(fid,1,'ushort')-1;
            att.Remarks1{ip}=fread(fid,2,'*char')';
            fread(fid,48*att.DataNumber(ip),'int8');
            att.StatuspR(ip)=fread(fid,1,'short');
            att.Roll(ip)=fread(fid,1,'short')*1e-1;
            att.Pitch(ip)=fread(fid,1,'short')*1e-1;
            att.StatusH(ip)=fread(fid,1,'short');
            att.Heave(ip)=fread(fid,1,'short')*1e-2;
            att.Remarks2{ip}=char(fread(fid,19,'short')');
            
            echo.DataSize(ip)=fread(fid,1,'ulong')/4;
            echo.pos(ip)=ftell(fid);
            fseek(fid,4*echo.DataSize(ip),0);
            fclose(fid);
        end
        
        nb_samples=floor(nanmax(echo.DataSize)/8);
        echo.Data=nan(nanmax(echo.DataSize),nb_pings);
        
        for u=1:nb_pings
            ip=idx_pings(u);
            if ~isempty(load_bar_comp)
                str_disp=sprintf('Getting Ping Data for %s',filename_dat{ip});
                set(load_bar_comp.progress_bar, 'Value',ip);
                load_bar_comp.progress_bar.setText(str_disp);
            end
            
            fid=fopen(filename_dat{ip},'r','n');
            
            fseek(fid,echo.pos(ip),-1);
            data_temp=fread(fid,echo.DataSize(ip),'long');
            echo.Data(1:length(data_temp),u)=data_temp;
            fclose(fid);
        end
        
        echo.comp_sig_1=echo.Data(1:8:end,:)+1j*echo.Data(2:8:end,:);
        echo.comp_sig_2=echo.Data(3:8:end,:)+1j*echo.Data(4:8:end,:);
        echo.comp_sig_3=echo.Data(5:8:end,:)+1j*echo.Data(6:8:end,:);
        echo.comp_sig_4=echo.Data(7:8:end,:)+1j*echo.Data(8:8:end,:);
        
        idx_s=1:nb_samples;
        %         SigIn=2*sqrt(...
        %             (real(echo.comp_sig_1(idx_s,:))+real(echo.comp_sig_2(idx_s,:))+real(echo.comp_sig_3(idx_s,:))+real(echo.comp_sig_4(idx_s,:))).^2+...
        %             (imag(echo.comp_sig_1(idx_s,:))+imag(echo.comp_sig_2(idx_s,:))+imag(echo.comp_sig_3(idx_s,:))+imag(echo.comp_sig_4(idx_s,:))).^2 ...
        %             )/2^32/sqrt(2);
        
        SigIn=4*sqrt(...
            (real(echo.comp_sig_1(idx_s,:))+real(echo.comp_sig_2(idx_s,:))).^2+...
            (imag(echo.comp_sig_1(idx_s,:))+imag(echo.comp_sig_2(idx_s,:))).^2 ...
            )/2^32/sqrt(2);
        
        EL=20*log10(SigIn);
        
        PowerdB=EL-(SL+ME);
        
        %         alongphi_1=fcv_phase(echo.comp_sig_1(idx_s,:),echo.comp_sig_2(idx_s,:));
        %         acrossphi_1=fcv_phase(echo.comp_sig_3(idx_s,:),echo.comp_sig_4(idx_s,:));
        %
        alongphi=angle(echo.comp_sig_2(idx_s,:).*conj(echo.comp_sig_1(idx_s,:)));
        acrossphi=angle(echo.comp_sig_4(idx_s,:).*conj(echo.comp_sig_3(idx_s,:)));
        
        
        AlongAngle=180/pi*asin(bsxfun(@rdivide,c*alongphi,(2*pi*params.Frequency(idx_pings)).*(L0*cosd(att.Pitch(idx_pings)))));
        AcrossAngle=-180/pi*asin(bsxfun(@rdivide,c*acrossphi,(2*pi*params.Frequency(idx_pings)).*(L0*cosd(att.Roll(idx_pings)))));
        
        fwrite(fileID(strcmp(fields,'alongangle')),double(AlongAngle)/factor_fields(strcmpi(fields,'alongangle')),fmt_fields{strcmpi(fields,'alongangle')});
        fwrite(fileID(strcmp(fields,'acrossangle')),double(AcrossAngle)/factor_fields(strcmpi(fields,'acrossangle')),fmt_fields{strcmpi(fields,'acrossangle')});
        fwrite(fileID(strcmp(fields,'power')),db2pow_perso(double(PowerdB))/factor_fields(strcmpi(fields,'power')),fmt_fields{strcmpi(fields,'power')});
    end
    
    %R=(1:nb_samples)'/nb_samples*params.Range;
    
    R=(1:nb_samples)'*0.029601;
    T=2*R/c;
    
    a=0.19;
    k=2*pi*params.Frequency/c;
    psi=5.78./(k*a).^2;
    
    
    config_current.TransceiverName='FCV30';
    config_current.Gain=G/2;
    config_current.SaCorrection=0;
    config_current.Frequency=38000;
    config_current.ChannelID=header.Model;
    config_current.FrequencyMaximum=38000;
    config_current.FrequencyMinimum=38000;
    config_current.EquivalentBeamAngle=10*log10(psi(1));
    config_current.AngleSensitivityAlongship=1/L0;
    config_current.AngleSensitivityAthwartship=1/L0;
    config_current.PulseLength=params.TXPulseWidth(1);
    
    echo.Data(nanmax(echo.DataSize)+1:end,:)=[];
    
    sub_ac_data_temp=sub_ac_data_cl.sub_ac_data_from_files(curr_data_name,[nb_samples nb_pings_tot],fields);
    
    params_current.Time=NMEA.UTC;
    params_current.BandWidth(:)=params.ChirpWidth(1);
    params_current.ChannelMode=params.Mode;
    params_current.Frequency(:)=params.Frequency;
    params_current.FrequencyEnd(:)=params.Frequency+params.ChirpWidth(1)/2;
    params_current.FrequencyStart(:)=params.Frequency-params.ChirpWidth(1)/2;
    params_current.PulseLength(:)=params.TXPulseWidth(1);
    params_current.SampleInterval(:)=nanmean(diff(T,1,1),1);
    params_current.Absorption(:)=alpha;
    params_current.TransmitPower(:)=2000;
    env_data=env_data_cl();
    env_data.SoundSpeed=c;
    
    gps_data=gps_data_cl('Time',NMEA.UTC,'Lat',NMEA.Latitude,'Long',NMEA.Longitude);
    att_data=attitude_nav_cl('Time',NMEA.UTC,'Heading',NMEA.VesselCourse,'Pitch',att.Pitch,'Pitch',att.Roll,'Heave',att.Heave);
    
    ac_data_temp=ac_data_cl('SubData',sub_ac_data_temp,...
        'Nb_samples',length(R),...
        'Nb_pings',length(params_current.Time),...
        'MemapName',curr_data_name_t);
    
    trans_obj=transceiver_cl('Data',ac_data_temp,...
        'AttitudeNavPing',att_data,...
        'GPSDataPing',gps_data,...
        'Range',R(:,1),...
        'Time',params_current.Time,...
        'Config',config_current,...
        'Params',params_current);
    

    
    layers(ilay)=layer_cl('ChannelID',{'FCV30'},...
        'Filename',{ini_config_files{iconfig}},...
        'Filetype','FCV30','Transceivers'...
        ,trans_obj,'GPSData',gps_data,'AttitudeNav',att_data,'EnvData',env_data);
    clear echo att NMEA params header;
    for ifif=1:numel(fields)
        fclose(fileID(ifif));
    end
end
if ~isempty(load_bar_comp)
    load_bar_comp.progress_bar.setText('');
end
end

function sig_phase=fcv_phase(s1,s2)

p1=sqrt(real(s1).^2+imag(s1).^2);
p2=sqrt(real(s2).^2+imag(s2).^2);

sig_phase=acos((real(s1).*real(s2)+imag(s1).*imag(s2))./(p1.*p2));
sig_phase((real(s1).*imag(s2)-real(s2).*imag(s1))<0)=-sig_phase((real(s1).*imag(s2)-real(s2).*imag(s1))<0);


end

