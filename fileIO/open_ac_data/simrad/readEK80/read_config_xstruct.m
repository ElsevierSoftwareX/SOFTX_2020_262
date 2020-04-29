function [header,config]=read_config_xstruct(xstruct)

conf=xstruct.Configuration;
header=conf.Header.Attributes;


Transceivers=conf.Transceivers;

nb_transceivers=length(Transceivers.Transceiver);
header.transceivercount=nb_transceivers;

i_trans=0;

for i=1:nb_transceivers
    
    if nb_transceivers>1
        Transceiver=Transceivers.Transceiver{i};
    else
        Transceiver=Transceivers.Transceiver;
    end
    
    config_temp=Transceiver.Attributes;
    
    
    Channels=Transceiver.Channels;
    Channel_tot=Channels.Channel;
    if ~iscell(Channel_tot)
        Channel_tot={Channel_tot};
    end
    
    for icha=1:length(Channel_tot)
        i_trans=i_trans+1;
        Channel=Channel_tot{icha};
        att=fieldnames(Channel.Attributes);
        for j=1:length(att)
            config_temp.(att{j})=Channel.Attributes.(att{j});
        end
        
        Transducer=Channel.Transducer;
        att=fieldnames(Transducer.Attributes);
        for j=1:length(att)
            if strcmp((att{j}),'SerialNumber')
                config_temp.TransducerSerialNumber=Transducer.Attributes.(att{j});
            else
                config_temp.(att{j})=Transducer.Attributes.(att{j});
            end
        end
        
        if isfield(Transducer,'FrequencyPar')
            att=fieldnames(Transducer.FrequencyPar{1}.Attributes);
            length_cal_fm=length(Transducer.FrequencyPar);
            for iat=1:length(att)
                freq_struct.(att{iat})=nan(1,length_cal_fm);
                
                for ic=1:length_cal_fm
                    freq_struct.(att{iat})(ic)=str2double(Transducer.FrequencyPar{ic}.Attributes.(att{iat}));
                end
            end
            config_temp.Cal_FM=freq_struct;
        end
        config{i_trans}=structfun(@read_conf_fields,config_temp,'un',0);
        
    end
end


if isfield(conf,'Transducers')
    
    Transducers=conf.Transducers.Transducer;
    nb_transducers=length(Transducers);
    
    for i=1:nb_transducers
        if nb_transducers>1
            Transducer=Transducers{i};
        else
            Transducer=Transducers;
        end
        
        config_temp=Transducer.Attributes;
        if isfield(config_temp,'TransducerCustomName')
            i_trans=find(~cellfun(@isempty,strfind(cellfun(@(x) x.ChannelIdShort,config,'un',0),config_temp.TransducerCustomName)));
        else
            i_trans=[];
        end
        
        if isempty(i_trans)
            continue;
        end
        
        att=fieldnames(Transducer.Attributes);
        for j=1:length(att)
            config_temp.(att{j})=Transducer.Attributes.(att{j});
        end
        
        
        for itrans_out=i_trans
            struct_tmp=structfun(@read_conf_fields,config_temp,'un',0);
            n_fields=fieldnames(struct_tmp);
            for ifi = 1:numel(n_fields)
                config{itrans_out}.(n_fields{ifi}) = struct_tmp.(n_fields{ifi});
            end
        end
        
    end
end


sensor=[];
if isfield(conf,'ConfiguredSensors')
    if isfield(conf.ConfiguredSensors,'Sensor')
        
        Sensors=conf.ConfiguredSensors.Sensor;
        nb_sensors=length(Sensors);
        
        for i=1:nb_sensors
            if nb_sensors>1
                Sensor=Sensors{i};
            else
                Sensor=Sensors;
            end
            
            sensor_temp=Sensor.Attributes;
            
            
            att=fieldnames(Sensor.Attributes);
            for j=1:length(att)
                sensor_temp.(att{j})=Sensor.Attributes.(att{j});
            end
            
            
            fields=fieldnames(sensor_temp);
            
            for jj=1:length(fields)
                val_temp=sscanf([sensor_temp.(fields{jj}) ';'],'%f;');
                if any(isnan(val_temp))||isempty(val_temp)
                    sensor(i).(fields{jj})=sensor_temp.(fields{jj});
                else
                    sensor(i).(fields{jj})=val_temp;
                end
                
            end
        end
    end
end

end



function y = read_conf_fields(x)

if isstruct(x)
    y=x;
    return;
end

val_temp=sscanf([x ';'],'%f;');

if any(isnan(val_temp))||isempty(val_temp)
    y=deblank(x);
else
    y=val_temp;
end

end