function layers=read_crest(Filename_cell,varargin)

p = inputParser;
if ~iscell(Filename_cell)
    Filename_cell={Filename_cell};
end

[path_to_mem_def,~,~]=fileparts(Filename_cell{1});

addRequired(p,'Filename_cell',@(x) ischar(x)||iscell(x));
addParameter(p,'PathToMemmap',path_to_mem_def);
addParameter(p,'FieldNames',{});
addParameter(p,'CVSCheck',0);
addParameter(p,'CVSroot','');
addParameter(p,'SvCorr',1);
parse(p,Filename_cell,varargin{:});


dir_data=p.Results.PathToMemmap;

machineformat = 'ieee-le'; %IEEE floating point with little-endian byte ordering
precision = 'short'; %2-byte

cvs_root=p.Results.CVSroot;

if ~isequal(Filename_cell, 0)
    
    
    
    for uu=1:length(Filename_cell)
        
        
        FileName=Filename_cell{uu};
        filenumber=str2double(FileName(end-7:end));
        fid = fopen(fullfile(FileName),'r',machineformat);
        
        if fid == -1
            warning(['Unable to open file ' sprintf('d%07d',filenumber)]);
            data=[];
        end
        idx_mess=1;
        while (true)
            type_temp=fread(fid,1,precision);
            if (feof(fid))
                break;
            end
            type(idx_mess)=type_temp;          %type (32="Bundled")
            ping_num(idx_mess)=fread(fid,1,precision);           %sequence number
            spare(idx_mess)=fread(fid,1,precision); %spare
            origin(idx_mess)=fread(fid,1,precision); %origin
            target(idx_mess)=fread(fid,1,precision); %target
            length_mess(idx_mess)=fread(fid,1,precision); %length
            
            if type(idx_mess)==32
                nb_echoes=fread(fid,1,precision);
                
                for u=1:nb_echoes
                    first_sample=fread(fid,1,precision);
                    nb_samples=fread(fid,1,precision);
                    samples=fread(fid,2*nb_samples,precision);
                    if nb_samples==numel(samples)/2
                        sample_real(first_sample:first_sample+nb_samples-1,idx_mess)=samples(1:2:end)';              %real part of sample
                        sample_imag(first_sample:first_sample+nb_samples-1,idx_mess)=samples(2:2:end)';
                    else
                        r_samp=samples(1:2:end)';
                        i_samp=samples(2:2:end)';
                        sample_real(first_sample:first_sample+numel(r_samp)-1,idx_mess)=r_samp;              %real part of sample
                        sample_imag(first_sample:first_sample+numel(i_samp)-1,idx_mess)=i_samp;
                    end
                    %sample_num(first_sample:first_sample+nb_samples-1,idx_mess)=(first_sample:first_sample+nb_samples-1)';
                end
                idx_mess=idx_mess+1;
            end
        end
        fclose(fid);
        
        pings=unique(ping_num);
        samples_val_real=nan(size(sample_real,1),nanmax(pings));
        samples_val_imag=nan(size(sample_real,1),nanmax(pings));
        
        for j=1:nanmax(pings)
            idx=(pings(j)==ping_num);
            samples_val_real(1:end,j)=nansum(sample_real(:,idx),2)/nansum(idx);
            samples_val_imag(1:end,j)=nansum(sample_imag(:,idx),2)/nansum(idx);
        end
        clear sample_real sample_imag ping_num;
        
        
        
        
        ifileInfo=parse_ifile(FileName);
        
        system_calibration=ifileInfo.system_calibration;
        depth_factor=ifileInfo.depth_factor;
        
        samples_val_real_cal=samples_val_real./system_calibration;
        samples_val_imag_cal=samples_val_imag./system_calibration;
        
        start_time=ifileInfo.start_date;
        end_time=ifileInfo.finish_date;
        
        survey_data=survey_data_cl('Snapshot',ifileInfo.snapshot,'Stratum',ifileInfo.stratum,'Transect',ifileInfo.transect);
        
        [gps_data,attitude_data]= read_n_file(fullfile(FileName),start_time,end_time);
        
        samples_num=(1:size(samples_val_imag,1))';
        trans_range=samples_num/depth_factor;
        number=(1:size(samples_val_imag,2));
        Time=linspace(start_time,end_time,length(number));
        
        gps_data_ping=gps_data.resample_gps_data(Time);
        attitude_data_pings=attitude_data.resample_attitude_nav_data(Time);
        
        
        power_ori=(samples_val_real_cal.^2+samples_val_imag_cal.^2);
        
        if strcmp(ifileInfo.sounder_type,'ES70')||strcmp(ifileInfo.sounder_type,'ES60')
            corr=-repmat(es60_error((1:size(power_ori,2))-ifileInfo.es60_zero_error_ping_num),size(power_ori,1),1);
        else
            corr=zeros(size(power_ori));
        end
        
        sv=10*log10(power_ori/p.Results.SvCorr)+10*log10(depth_factor)+corr;
         nb_pings=numel(Time);
         params.Time=Time;
        [config,params]=config_from_ifile(FileName,nb_pings);
        
        [~,curr_filename,~]=fileparts(tempname);
        curr_name=fullfile(dir_data,curr_filename);
        
        sub_ac_data=[sub_ac_data_cl('field','power','memapname',curr_name,'data',single(power))...
            sub_ac_data_cl('field','sv','memapname',curr_name,'data',sv)];
        
        ac_data_temp=ac_data_cl('SubData',sub_ac_data,...
            'Nb_samples',length(trans_range),...
            'Nb_pings',size(power,2),...
            'MemapName',curr_name);
        

        transceiver=transceiver_cl('Data',ac_data_temp,...
            'Config',config,...
            'Params',params,...
            'Range',trans_range,...
            'Time',Time,...
            'GPSDataPing',gps_data_ping,...
            'Mode','CW',...
            'AttitudeNavPing',attitude_data_pings);
        trans_obj(idx).set_absorption(ifileInfo.absorption_coefficient/1000);
        
        envdata=env_data_cl('SoundSpeed',ifileInfo.sound_speed);
        
        layers(uu)=layer_cl('Filename',{FileName},'Filetype','CREST',...
            'Transceivers',transceiver,'GPSData',gps_data,'AttitudeNav',attitude_data,...
            'Frequencies',38000,'OriginCrest',FileName,'EnvData',envdata);
            layers(uu).set_survey_data(survey_data);
        
        if p.Results.CVSCheck&&~strcmp(cvs_root,'')
            layers(uu).CVS_BottomRegions(cvs_root);
        end
        
    end
end
