function [header, frequencies,channels] = readEKRaw_ReadHeader(fid)

fread(fid, 1, 'int32');
[dgType, dgTime] = readEK60Header_v2(fid);
dgTime = datenum(1601, 1, 1, 0, 0, dgTime);

header = [];
frequencies = [];
channels = [];

switch dgType
    case 'CON0'
        configheader = readEKRaw_ReadConfigHeader(fid);
        configheader.time = dgTime;
        
        %  extract individual xcvr configurations and store list of frequencies
        frequencies = zeros(1, configheader.transceivercount);
        channels = cell(1, configheader.transceivercount);
        for i = 1:configheader.transceivercount
            configXcvr(i) = readEKRaw_ReadTransceiverConfig(fid);
            frequencies(i) = configXcvr(i).frequency;
            channels{i}= deblank(configXcvr(i).channelid);
        end
        
        %  create the configuration structure - store header and xcvr configs
        header = struct('header',configheader,'transceiver',configXcvr);
        
        fread(fid, 1, 'int32');
    otherwise
        fseek(fid,-4,'cof');        
end