function [trans_obj,envdata,NMEA,mru0_att]=data_from_raw_idx_cl_v7(path_f,idx_raw_obj,varargin)
HEADER_LEN=12;
nb_samples=idx_raw_obj.get_nb_samples_per_channels();
nb_samples_max=nansum(nb_samples);
p = inputParser;
addRequired(p,'path_f',@(x) ischar(x));
addRequired(p,'idx_raw_obj',@(x) isa(x,'raw_idx_cl'));
addParameter(p,'Frequencies',[],@isnumeric);
addParameter(p,'Channels',{},@iscell);
addParameter(p,'GPSOnly',0,@isnumeric);
addParameter(p,'DataOnly',0,@isnumeric);
addParameter(p,'PathToMemmap',path_f,@ischar);
addParameter(p,'FieldNames',{});
addParameter(p,'load_bar_comp',[]);
addParameter(p,'env_data',env_data_cl.empty());

addParameter(p,'block_len',[],@(x) isempty(x)||x>0);


parse(p,path_f,idx_raw_obj,varargin{:});
results=p.Results;
Frequencies=results.Frequencies;
Channels=deblank(results.Channels);
gps_only=p.Results.GPSOnly;
trans_obj=transceiver_cl.empty();

envdata_def=p.Results.env_data;

envdata=env_data_cl();
    
NMEA={};
mru0_att=attitude_nav_cl.empty();

filename=fullfile(path_f,idx_raw_obj.filename);

recent_times=idx_raw_obj.time_dg>datenum('01-Jan-1601');

if any(recent_times)
    prop_idx=properties(idx_raw_obj);
    for iprop=1:numel(prop_idx)
        if numel(idx_raw_obj.(prop_idx{iprop}))==numel(recent_times)
            idx_raw_obj.(prop_idx{iprop})(~recent_times)=[];
        end
    end
end

ftype=get_ftype(filename);

load_bar_comp=results.load_bar_comp;
block_len=results.block_len;

if isempty(block_len)
    block_len=get_block_len(10*nb_samples_max,'cpu');
end

array_type='double';

switch ftype
    case 'EK80'
        [~,config]=read_EK80_config(filename);
        nb_trans_tot=length(config);
        
        freq=nan(1,nb_trans_tot);
        CIDs=cell(1,nb_trans_tot);
        
        for uif=1:length(freq)
            freq(uif)=config{uif}.Frequency;
            CIDs{uif}=deblank(config{uif}.ChannelID);
        end
        
    case 'EK60'
        fid=fopen(fullfile(path_f,idx_raw_obj.filename),'r','n','US-ASCII');
        %fid=fopen(fullfile(path_f,idx_raw_obj.filename),'r');
        [header, freq,CIDs] = readEKRaw_ReadHeader(fid);
        fclose(fid);
        config_EK60=header.transceiver;
        
        for uif=1:length(freq)
            config_EK60(uif).soundername=deblank(header.header.soundername);
        end
end


if isempty(Frequencies)
    idx_freq=(1:length(freq))';
else
    idx_freq=find(ismember(CIDs,Channels));
end

channels=unique(idx_raw_obj.chan_dg(~isnan(idx_raw_obj.chan_dg)));
%%
idx_freq(idx_freq>numel(channels))=[];

channels=channels(idx_freq);
CIDs_freq=CIDs(idx_freq);

if isempty(channels)
    warndlg_perso([],'Failed',sprintf('Cannot open file %s, cannot find required channels',filename));
    return;
end

trans_obj(length(CIDs_freq))=transceiver_cl();
nb_trans=length(idx_freq);

nb_pings=idx_raw_obj.get_nb_pings_per_channels();
nb_pings=nb_pings(idx_freq);
nb_pings(nb_pings<0)=0;

%block_len=nanmin(nanmin(ceil(nb_pings/2)),block_len);

nb_samples=idx_raw_obj.get_nb_samples_per_channels();
nb_samples=nb_samples(idx_freq);
nb_samples(nb_samples<0)=0;

nb_samples_cell=idx_raw_obj.get_nb_samples_per_block_per_channels(1);
nb_samples_cell=nb_samples_cell(idx_freq);

[nb_samples_group,~,~,block_id]=cellfun(@(x) group_pings_per_samples(x,1:numel(x)),nb_samples_cell,'un',0);

nb_samples_per_block=idx_raw_obj.get_nb_samples_per_block_per_channels(block_len);
nb_samples_per_block=nb_samples_per_block(idx_freq);

if gps_only>0
    nb_pings=nanmin(ones(1,length(CIDs_freq)),nb_pings);
    nb_samples=nanmin(ones(1,length(CIDs_freq)),nb_samples);
end

nb_nmea=idx_raw_obj.get_nb_nmea_dg();

time_nmea=idx_raw_obj.get_time_dg('NME0');
NMEA.time= time_nmea;
NMEA.string= cell(1,nb_nmea);
NMEA.type= cell(1,nb_nmea);
NMEA.ori= cell(1,nb_nmea);

params_cl_init(nb_trans)=params_cl();

[fields,~,fmt_fields,factor_fields,default_values]=init_fields();

curr_data_name=cell(nb_trans,numel(fields));
curr_data_name_t=cell(nb_trans,1);

for i=1:nb_trans
    data.pings(i).number=nan(1,nb_pings(i),array_type);
    data.pings(i).time=nan(1,nb_pings(i),array_type);
    %data.pings(i).samples=(1:nb_samples(i))';
    trans_obj(i).Params=params_cl(nb_pings(i));
    
    if gps_only==0
        [~,curr_filename,~]=fileparts(tempname);
        curr_data_name_t{i}=fullfile(p.Results.PathToMemmap,curr_filename);
        
        for ifif=1:numel(fields)
            curr_data_name{i,ifif}=[curr_data_name_t{i} fields{ifif} '.bin'];
        end
    end
end


block_i=ones(1,nb_trans);
block_nb=ones(1,nb_trans);

data_tmp=cell(1,nb_trans);
i_ping = ones(nb_trans,1);
i_nmea=0;
id_mru0=0;
%fil_process=0;
conf_dg=0;
env_dg=0;

prop_params=properties(params_cl);
%prop_config=properties(config_cl);
prop_env=properties(env_data_cl);

param_str_init=cell(1,nb_trans);

param_str_init_over=cell(1,numel(CIDs));
param_str_init(:)={''};
param_str_init_over(:)={''};
idx_mru0=strcmp(idx_raw_obj.type_dg,'MRU0');

mru0_att=attitude_nav_cl('Time',idx_raw_obj.time_dg(idx_mru0)');

mode=cell(1,length(trans_obj));

%fid=fopen(filename,'r');
fid=fopen(filename,'r','n','US-ASCII');
str_disp=sprintf('Opening File %s',filename);
if ~isempty(load_bar_comp)
    set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',length(idx_raw_obj.type_dg), 'Value',0);
    load_bar_comp.progress_bar.setText(str_disp);
else
    disp(str_disp);
end



dg_type_keep={'XML0','CON0','NME0','RAW0','RAW3','FIL1','MRU0'};

if gps_only>0
    dg_type_keep={'XML0','CON0','NME0','RAW0','RAW3','FIL1'};
end

if p.Results.DataOnly>0
    dg_type_keep={'XML0','CON0','RAW0','RAW3','FIL1'};
end

idx_keep=ismember(idx_raw_obj.type_dg,dg_type_keep)&(isnan(idx_raw_obj.chan_dg)|ismember(idx_raw_obj.chan_dg,channels));


props=properties(idx_raw_obj);
for iprop=1:numel(props)
    if numel(idx_raw_obj.(props{iprop}))==numel(idx_keep)
        idx_raw_obj.(props{iprop})(~idx_keep)=[];
    end
end

nb_dg=length(idx_raw_obj.type_dg);

% idg_time=idx_raw_obj.time_dg();
% [~,idg_sort]=sort(idg_time);

for idg=1:nb_dg
    pos=ftell(fid);
    
    if (idx_raw_obj.pos_dg(idg)-pos+HEADER_LEN)<0
        continue;
    end
    
    %     if feof(fid)
    %         disp('');
    %         continue;
    %     end
    
    dgTime=idx_raw_obj.time_dg(idg);
    if ~isempty(load_bar_comp)
        set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',nb_dg, 'Value',idg);
    end
    
    switch  idx_raw_obj.type_dg{idg}
        case 'XML0'
            
            fseek(fid,idx_raw_obj.pos_dg(idg)-pos+HEADER_LEN,'cof');
            t_line=(fread(fid,idx_raw_obj.len_dg(idg)-HEADER_LEN,'*char',0,'l'))';
            t_line=deblank(t_line);
            if contains(t_line,'<Configuration>')&&conf_dg==1
                if conf_dg==1
                    fread(fid, 1, 'int32', 0,'l');
                    continue;
                end
                
            elseif contains(t_line,'<Environment>')&&env_dg==1
                fread(fid, 1, 'int32', 0, 'l');
                continue;
            elseif contains(t_line,'<Parameter>')
                idx = find(strcmp(t_line,param_str_init));
                idx_over = find(strcmp(t_line,param_str_init_over), 1);
                if ~isempty(idx)
                    dgTime=idx_raw_obj.time_dg(idg);
                    fread(fid, 1, 'int32', 0, 'l');
                    params_cl_init(idx).Time=dgTime;
                    trans_obj(idx).Params.Time(i_ping(idx))=dgTime;
                    
                    continue;
                elseif ~isempty(idx_over)
                    continue;
                end
            elseif strcmpi(t_line,'')
                continue;
            end
            
            
            [~,output,type]=read_xml0(t_line);%50% faster than the old version!
            
            switch type
                
                case'Configuration'
                    config_temp=output;
                    
                    for iout=1:length(config_temp)
                        idx = find(strcmp(deblank(CIDs_freq),deblank(config_temp{iout}.ChannelID)));
                        if ~isempty(idx)
                            trans_obj(idx).Config=config_obj_from_xml_struct(config_temp{iout},t_line);
                        end
                    end
                case 'Environment'
                    if ~isempty(output)
                        props=fieldnames(output);
                        if isempty(envdata)
                            envdata=env_data_cl();
                        end
                        
                        for iii=1:length(props)
                            if  any(strcmpi(prop_env,props{iii}))
                                envdata.(props{iii})=output.(props{iii});
                            else
                                if ~isdeployed()
                                    fprintf('New parameter in Environment XML: %s\n', props{iii});
                                end
                            end
                        end
                        
                    end
                case 'Parameter'
                    params_temp=output;
                    idx = find(strcmp(deblank(CIDs_freq),deblank(params_temp.ChannelID)));
                    idx_over = find(strcmp(deblank(CIDs),deblank(params_temp.ChannelID)));
                    if ~isempty(idx_over)
                        param_str_init_over{idx_over}=t_line;
                    end
                    dgTime=idx_raw_obj.time_dg(idg);
                    fields_params=fieldnames(params_temp);
                    
                    if ~isempty(idx)
                        param_str_init{idx}=t_line;
                        
                        params_cl_init(idx).Time=dgTime;
                        for jj=1:length(fields_params)
                            switch fields_params{jj}
                                case 'PulseDuration'
                                    params_cl_init(idx).PulseLength=params_temp.(fields_params{jj});
                                otherwise
                                    if ismember(fields_params{jj},prop_params)
                                        params_cl_init(idx).(fields_params{jj})=params_temp.(fields_params{jj});
                                    else
                                        if ~isdeployed()
                                            fprintf('New parameter in Parameters XML: %s\n', fields_params{jj});
                                        end
                                    end
                            end
                        end
                        
                        trans_obj(idx).Params.Time(i_ping(idx))=dgTime;
                        trans_obj(idx).TransducerImpedance=cell(trans_obj(idx).Config.NbQuadrants,nb_pings(idx));
                        
                        
                        for jj=1:length(prop_params)
                            if ~isempty(params_cl_init(idx).(prop_params{jj}))
                                if ischar(params_cl_init(idx).(prop_params{jj}))
                                    trans_obj(idx).Params.(prop_params{jj}){i_ping(idx)}=(params_cl_init(idx).(prop_params{jj}));
                                else
                                    trans_obj(idx).Params.(prop_params{jj})(i_ping(idx))=(params_cl_init(idx).(prop_params{jj}));
                                end
                            else
                                if ~isdeployed()
                                    fprintf('Parameter not found in Parameters XML: %s\n', prop_params{jj});
                                end
                            end
                        end
                        
                        
                        
                    end
            end
            
        case 'NME0'
            if  gps_only<=1
                fseek(fid,idx_raw_obj.pos_dg(idg)-pos+HEADER_LEN,'cof');
                i_nmea=i_nmea+1;
                NMEA.string{i_nmea}=fread(fid,idx_raw_obj.len_dg(idg)-HEADER_LEN,'*char', 0, 'l')';
                if numel(NMEA.string{i_nmea})>=6
                    idx=strfind(NMEA.string{i_nmea},',');
                    if ~isempty(idx)
                        NMEA.type{i_nmea}=NMEA.string{i_nmea}(4:idx(1)-1);
                        NMEA.ori{i_nmea}=NMEA.string{i_nmea}(2:3);
                    else
                        NMEA.type{i_nmea}='';
                        NMEA.ori{i_nmea}='';
                    end
                else
                    NMEA.type{i_nmea}='';
                    NMEA.ori{i_nmea}='';
                end
            end
        case 'FIL1'
            
            fseek(fid,idx_raw_obj.pos_dg(idg)-pos+HEADER_LEN,'cof');
            stage=fread(fid,1,'int16',0,'l');
            fread(fid,2,'char',0,'l');
            filter_coeff_temp.channelID = (fread(fid,128,'*char',0, 'l')');
            filter_coeff_temp.NoOfCoefficients=fread(fid,1,'int16',0,'l');
            filter_coeff_temp.DecimationFactor=fread(fid,1,'int16',0,'l');
            filter_coeff_temp.Coefficients=fread(fid,2*filter_coeff_temp.NoOfCoefficients,'single',0,'l');
            idx = find(strcmp(deblank(CIDs_freq),deblank(filter_coeff_temp.channelID)));
            
            if ~isempty(idx)
                props=fieldnames(filter_coeff_temp);
                for iii=1:length(props)
                    if isprop(filter_cl(), (props{iii}))
                        trans_obj(idx).Filters(stage).(props{iii})=filter_coeff_temp.(props{iii});
                    end
                end
            end
            
        case {'RAW3';'RAW0'}
            
            switch idx_raw_obj.type_dg{idg}
                case 'RAW3'
                    %disp(dgType);
                    % read channel ID
                    fseek(fid,idx_raw_obj.pos_dg(idg)-pos+HEADER_LEN,'cof');
                    
                    channelID = (fread(fid,128,'*char',0, 'l')');
                    idx = find(strcmp(deblank(CIDs_freq),deblank(channelID)));
                    
                    if isempty(idx)||i_ping(idx)>nb_pings(idx)
                        continue;
                    end
                    
                    datatype=fread(fid,1,'int16',0,'l');
                    fread(fid,1,'int16',0,'l');
                    data.pings(idx).datatype=fliplr(dec2bin(datatype,11));
                    
                    temp=fread(fid,2,'int32',0,'l');
                    %  store sample number if required/valid
                    number=i_ping(idx);
                    
                    data.pings(idx).channelID=channelID;
                    
                    data.pings(idx).offset(i_ping(idx))=temp(1);
                    data.pings(idx).sampleCount(i_ping(idx))=temp(2);
                    data.pings(idx).number(i_ping(idx))=number;
                    data.pings(idx).time(i_ping(idx))=dgTime;
                    sampleCount=temp(2);
                    if data.pings(idx).datatype(1)==dec2bin(1)
                        if (sampleCount > 0)
                            
                            if block_i(idx)==1
                                data_tmp{idx}.power=-999*ones(nb_samples_per_block{idx}(block_nb(idx)),nanmin(block_len,nb_pings(idx)-i_ping(idx)+1));
                                if data.pings(idx).datatype(2)==dec2bin(1)
                                    data_tmp{idx}.AcrossPhi=zeros(nb_samples_per_block{idx}(block_nb(idx)),nanmin(block_len,nb_pings(idx)-i_ping(idx)+1));
                                    data_tmp{idx}.AlongPhi=zeros(nb_samples_per_block{idx}(block_nb(idx)),nanmin(block_len,nb_pings(idx)-i_ping(idx)+1));
                                end
                            end
                            
                            
                            
                            if data.pings(idx).datatype(2)==dec2bin(1)
                                
                                if sampleCount*4==idx_raw_obj.len_dg(idg)-HEADER_LEN-12-128
                                    data_tmp{idx}.power(1:sampleCount,block_i(idx))=(fread(fid,sampleCount,'int16',0,'l') * 0.011758984205624);
                                    angles=fread(fid,[2 sampleCount],'int8',0,'l');
                                    sampleCount=size(angles,2);
                                    data_tmp{idx}.AcrossPhi(1:sampleCount,block_i(idx))=angles(1,:);
                                    data_tmp{idx}.AlongPhi(1:sampleCount,block_i(idx))=angles(2,:);
                                end
                                
                            else
                                data_tmp{idx}.power(1:sampleCount,block_i(idx))=(fread(fid,sampleCount,'int16',0,'l') * 0.011758984205624);
                            end
                            
                            
                        end
                    else
                        
                        nb_cplx_per_samples=bin2dec(fliplr(data.pings(idx).datatype(8:end)));
                        if data.pings(idx).datatype(4)==dec2bin(1)
                            fmt='float32';
                        elseif data.pings(idx).datatype(3)==dec2bin(1)
                            fmt='int16';
                        end
                        
                        if (sampleCount > 0)
                            temp = fread(fid,[nb_cplx_per_samples sampleCount],fmt,0,'l');
                        else
                            temp=[];
                        end
                        
                        if mod(numel(temp),nb_cplx_per_samples)~=0
                            sampleCount=0;
                        else
                            sampleCount= numel(temp)/(nb_cplx_per_samples);
                        end
                        
                        if (sampleCount > 0)
                            if block_i(idx)==1
                                for isig=1:nb_cplx_per_samples/2
                                    data_tmp{idx}.(sprintf('comp_sig_%1d',isig))=zeros(nb_samples_per_block{idx}(block_nb(idx)),nanmin(block_len,nb_pings(idx)-i_ping(idx)+1));
                                end
                            end
                            id=find(trans_obj(idx).Params.PulseLength>0,1,'last');
                            Np=2*round(trans_obj(idx).Params.PulseLength(id)/trans_obj(idx).Params.SampleInterval(id));
%                             idx_reshuffle=[3 4 1 2];
%                             polarity=[-1 1 -1 1];
                            for isig=1:nb_cplx_per_samples/2
%                                 switch trans_obj(idx).Config.TransducerSerialNumber
%                                     case '28332'
%                                         if polarity(idx)>=1
%                                             data_tmp{idx}.(sprintf('comp_sig_%1d',idx_reshuffle(isig)))(1:sampleCount,block_i(idx))=(temp(1+2*(isig-1),:)+1i*temp(2+2*(isig-1),:));
%                                         else
%                                             data_tmp{idx}.(sprintf('comp_sig_%1d',idx_reshuffle(isig)))(1:sampleCount,block_i(idx))=conj(temp(1+2*(isig-1),:)+1i*temp(2+2*(isig-1),:));   
%                                         end
%                                     otherwise
%                                         data_tmp{idx}.(sprintf('comp_sig_%1d',isig))(1:sampleCount,block_i(idx))=temp(1+2*(isig-1),:)+1i*temp(2+2*(isig-1),:);
%                                 end
                                data_tmp{idx}.(sprintf('comp_sig_%1d',isig))(1:sampleCount,block_i(idx))=temp(1+2*(isig-1),:)+1i*temp(2+2*(isig-1),:);
                                
                                tmp_real=temp(1+2*(isig-1),1:Np);
                                tmp_imag=temp(2+2*(isig-1),1:Np);
                                
                                trans_obj(idx).TransducerImpedance{isig,i_ping(idx)}=tmp_real+1i*tmp_imag;
                            end
                        end
                        
                    end
                case 'RAW0'
                    chan=idx_raw_obj.chan_dg(idg);
                    idx=find(chan==channels);
                    
                    if isempty(idx)||i_ping(idx)>nb_pings(idx)
                        continue;
                    end
                    
                    %fseek(fid,idx_raw_obj.pos_dg(idg),'bof');
                    fseek(fid,idx_raw_obj.pos_dg(idg)-pos+HEADER_LEN,'cof');
                    data.pings(idx).time(i_ping(idx))=idx_raw_obj.time_dg(idg);
                    temp=fread(fid,4,'int8',0,'l');
                    if ~isempty(temp)
                        data.pings(idx).datatype=(dec2bin(256*temp(3)+temp(4),8));
                        data.pings(idx).mode(i_ping(idx))=256*temp(3)+temp(4);
                        
                        if block_i(idx)==1
                            data_tmp{idx}.power=-999*ones(nb_samples(idx),nanmin(block_len,nb_pings(idx)-i_ping(idx)+1));
                            if data.pings(idx).datatype(2)==dec2bin(1)
                                data_tmp{idx}.AcrossPhi=zeros(nb_samples(idx),nanmin(block_len,nb_pings(idx)-i_ping(idx)+1));
                                data_tmp{idx}.AlongPhi=zeros(nb_samples(idx),nanmin(block_len,nb_pings(idx)-i_ping(idx)+1));
                            end
                        end
                        
                        [data,power_tmp,angles]=readRaw0_v2(data,idx,i_ping(idx),fid);
                        
                        if i_ping(idx)==1
                            mode{idx}='CW';
                            [trans_obj(idx).Config,trans_obj(idx).Params]=config_from_ek60(data.pings(idx),config_EK60(idx_freq(idx)));
                        end
                        
                        data_tmp{idx}.power(1:numel(power_tmp),block_i(idx))=power_tmp;
                        if data.pings(idx).datatype(2)==dec2bin(1)
                            data_tmp{idx}.AcrossPhi(1:size(angles,2),block_i(idx))=angles(1,:);
                            data_tmp{idx}.AlongPhi(1:size(angles,2),block_i(idx))=angles(2,:);
                        end
                        
                        
                        
                        
                    else
                        if i_ping(idx)>1
                            data.pings(idx).transducerdepth(i_ping(idx)) = data.pings(idx).transducerdepth(i_ping(idx)-1) ;
                            data.pings(idx).frequency(i_ping(idx)) = data.pings(idx).frequency(i_ping(idx)-1) ;
                            data.pings(idx).transmitpower(i_ping(idx)) = data.pings(idx).transmitpower(i_ping(idx)-1) ;
                            data.pings(idx).pulselength(i_ping(idx)) = data.pings(idx).pulselength(i_ping(idx)-1) ;
                            data.pings(idx).bandwidth(i_ping(idx)) = data.pings(idx).bandwidth(i_ping(idx)-1) ;
                            data.pings(idx).sampleinterval(i_ping(idx)) = data.pings(idx).sampleinterval(i_ping(idx)-1) ;
                            data.pings(idx).soundvelocity(i_ping(idx)) = data.pings(idx).soundvelocity(i_ping(idx)-1) ;
                            data.pings(idx).absorptioncoefficient(i_ping(idx)) = data.pings(idx).absorptioncoefficient(i_ping(idx_chan)-1) ;
                        end
                    end
            end
            
            % instantiate acoustic data object
            if i_ping(idx)==1 && gps_only==0
                trans_obj(idx).Data = ac_data_cl('SubData',[],...
                    'Nb_samples', nb_samples_group{idx},...
                    'Nb_pings',   nb_pings(idx),...
                    'BlockId' , block_id{idx},...
                    'MemapName',  curr_data_name_t{idx});
            end
            
            if block_i(idx)==block_len||i_ping(idx)==nb_pings(idx)   
                idx_pings=(block_len*(block_nb(idx)-1)+1):i_ping(idx);
                mode{idx}=write_data(data.pings(idx).datatype,trans_obj(idx),data_tmp{idx},gps_only,(1:nb_samples_per_block{idx}(block_nb(idx))),idx_pings);
                block_i(idx)=0;
                block_nb(idx)=block_nb(idx)+1;
            end
            
            i_ping(idx) = i_ping(idx) + 1;
            block_i(idx)=block_i(idx)+1;
            
            
            
        case 'MRU0'
            id_mru0=id_mru0+1;
            fseek(fid,idx_raw_obj.pos_dg(idg)-pos+HEADER_LEN,'cof');
            tmp=fread(fid,4,'float32',0,'l');
            if~isempty(tmp)
                mru0_att.Heave(id_mru0) = tmp(1);
                mru0_att.Roll(id_mru0) = tmp(2);
                mru0_att.Pitch(id_mru0) = tmp(3);
                mru0_att.Heading(id_mru0) = tmp(4);
            end
            
            
    end
end
fclose(fid);



for i=1:nb_trans
    if block_i(i)>1
        trans_obj(i).Mode=write_data(data.pings(idx).datatype,trans_obj(i),data_tmp{idx},gps_only,(1:nb_samples_per_block{i}(block_i(i))),idx_pings);
    else
        trans_obj(i).Mode=mode{i};
    end
    
end

idx_rem_nmea=cellfun(@isempty,NMEA.string);
NMEA.string(idx_rem_nmea)=[];
NMEA.type(idx_rem_nmea)=[];
NMEA.time(idx_rem_nmea)=[];

%Complete Params if necessary

for idx=1:nb_trans    
    idx_nan=trans_obj(idx).Params.PulseLength==0;    
    for jj=1:length(prop_params)
        trans_obj(idx).Params.(prop_params{jj})(idx_nan)=[];        
    end   
end



switch ftype
    case 'EK80'
        
    case 'EK60'
        for i=1:length(idx_freq)
            [trans_obj(i).Config,trans_obj(i).Params]=config_from_ek60(data.pings(i),config_EK60(idx_freq(i)));
        end
        
        envdata.SoundSpeed=data.pings(1).soundvelocity(1);
end

if~isempty(envdata_def)   
    props=properties(envdata_def);
    for ipp=1:numel(props)
        if isnumeric(envdata_def.(props{ipp}))
            if ~isnan(envdata_def.(props{ipp}))
                envdata.(props{ipp})=envdata_def.(props{ipp});
            end
        else
            envdata.(props{ipp})=envdata_def.(props{ipp});
        end
    end
end

id_rem=[];
for i =1:nb_trans
    
    if ~any(trans_obj(i).Params.Absorption~=0)
        alpha= seawater_absorption(trans_obj(i).Params.Frequency(1)/1e3, (envdata.Salinity), (envdata.Temperature), (envdata.Depth),'fandg')/1e3;
        trans_obj(i).Params.Absorption(:)=alpha;
    end
    
    trans_obj(i).set_transceiver_time(data.pings(i).time);
    if gps_only==0
        trans_obj(i).set_transceiver_time(data.pings(i).time);
    else
        trans_obj(i).set_transceiver_time([data.pings(i).time dgTime]);
    end
    
    [~,range_t]=trans_obj(i).compute_soundspeed_and_range(envdata);   
    trans_obj(i).set_transceiver_range(range_t);
    trans_obj(i).set_absorption(envdata);
      
    % initialize bottom object, with right dimensions but no information
    trans_obj(i).Bottom = [];
end
trans_obj(id_rem)=[];

end


function mode=write_data(datatype,trans_obj,data_tmp,GPSOnly,idx_r,idx_pings)

if datatype(1)==dec2bin(1)
    if datatype(2)==dec2bin(1)||datatype(1)==dec2bin(0)
        [AlongAngle,AcrossAngle]=computesPhasesAngles_v3(data_tmp,...
            trans_obj.Config.AngleSensitivityAlongship,...
            trans_obj.Config.AngleSensitivityAthwartship,...
            datatype,...
            trans_obj.Config.TransducerName,...
            trans_obj.Config.AngleOffsetAlongship,...
            trans_obj.Config.AngleOffsetAthwartship);
    end
    
    mode='CW';
    
    if GPSOnly==0
        trans_obj.Data.replace_sub_data_v2('power',db2pow_perso(data_tmp.power),idx_r,idx_pings)
        if  datatype(2)==dec2bin(1)
            trans_obj.Data.replace_sub_data_v2('alongangle',AlongAngle,idx_r,idx_pings)
            trans_obj.Data.replace_sub_data_v2('acrossangle',AcrossAngle,idx_r,idx_pings)
        end
    end
    
else
    [~,powerunmatched]=compute_PwEK80(trans_obj.Config.Impedance,trans_obj.Config.Ztrd,datatype,data_tmp);
    trans_obj.Config.NbQuadrants=sum(contains(fieldnames(data_tmp),'comp_sig'));
    
    [data_tmp,mode]=match_filter_data(data_tmp,trans_obj.Params,trans_obj.Filters);
    if datatype(2)==dec2bin(1)||datatype(1)==dec2bin(0)
        [AlongAngle,AcrossAngle]=computesPhasesAngles_v3(data_tmp,...
            trans_obj.Config.AngleSensitivityAlongship,...
            trans_obj.Config.AngleSensitivityAthwartship,...
            datatype,...
            trans_obj.Config.TransducerName,...
            trans_obj.Config.AngleOffsetAlongship,...
            trans_obj.Config.AngleOffsetAthwartship);
        
    end
    switch mode
        case 'FM'
            [y,pow]=compute_PwEK80(trans_obj.Config.Impedance,trans_obj.Config.Ztrd,datatype,data_tmp);
        case 'CW'
            pow=powerunmatched;
    end
    
    if GPSOnly==0
        if strcmp(mode,'FM')
            trans_obj.Data.replace_sub_data_v2('powerunmatched',powerunmatched,idx_r,idx_pings)
            trans_obj.Data.replace_sub_data_v2('y_real',real(y),idx_r,idx_pings)
            trans_obj.Data.replace_sub_data_v2('y_imag',imag(y),idx_r,idx_pings)
        end
        trans_obj.Data.replace_sub_data_v2('power',pow,idx_r,idx_pings)
        trans_obj.Data.replace_sub_data_v2('alongangle',AlongAngle,idx_r,idx_pings)
        trans_obj.Data.replace_sub_data_v2('acrossangle',AcrossAngle,idx_r,idx_pings)
    end
end
end

