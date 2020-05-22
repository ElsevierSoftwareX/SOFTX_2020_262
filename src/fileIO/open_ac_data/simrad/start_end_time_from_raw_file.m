function [start_time,end_time] = start_end_time_from_raw_file(filename)

%% parameters
% block size for reading binary data in file
BLCK_SIZE = 1e6;

%% initialize results
start_time = 0;
end_time = 1e9;

%% open file
fid = fopen(filename,'r','n','US-ASCII');
if fid==-1
    return;
end

%% find start time in file
% by reading blocks of binary and looking for data start tags
found_start=false;
fseek(fid,0,'bof');
while ~feof(fid)&&~found_start
    
    pos = ftell(fid);
    
    % read block in strings
    str_read = fread(fid,BLCK_SIZE,'*char')';
    
    % check if tag is in it
    idx_dg = unique([strfind(str_read,'CON0') strfind(str_read,'XML0') strfind(str_read,'RAW0') strfind(str_read,'RAW3') strfind(str_read,'NME0')]);
    
    for ui=1:numel(idx_dg)
        % rewind till beggining of data packet
        idx_start = pos+idx_dg(ui)-1;
        fseek(fid,idx_start,-1);
        % and read time from the header
        [~,start_time] = readEK60Header_v2(fid);
        start_time=datenum(1601, 1, 1, 0, 0, start_time);
        % exit if date is good
        if start_time>datenum('01-Jan-1601')&&start_time<=now
            found_start=true;
            break;
        end       
        if ~contains(str_read,'RAW3')
            BLCK_SIZE=5*1e7;
        end
    end
    
    % if data not found, increase the data being read and reloop
    if ~feof(fid)
        fseek(fid,-3,'cof');
    end
end

% go to end of file
fseek(fid,0,'eof');

%% find end time in file
pos = ftell(fid);
BLCK_SIZE = nanmin(pos,1e6);
fseek(fid,-BLCK_SIZE,'cof');
found_end=false;

while pos >0&&~found_end
    
    % read block in strings
    pos = ftell(fid);    
    str_read = fread(fid,BLCK_SIZE,'*char')';    
    % check if tag is in it
    idx_dg = unique([strfind(str_read,'CON0') strfind(str_read,'XML0') strfind(str_read,'RAW0') strfind(str_read,'RAW3') strfind(str_read,'NME0')]);
    
    for ui=numel(idx_dg):-1:1
        % rewind till beggining of data packet
        idx_end = pos+idx_dg(ui)-1;
        fseek(fid,idx_end,-1);
        % and read time from the header
        [~,end_time] = readEK60Header_v2(fid);
        end_time=datenum(1601, 1, 1, 0, 0, end_time);
        % exit if date is good
        if end_time>start_time&&end_time>datenum('01-Jan-1601')&&end_time<=now
            found_end=true;
            break;
        end
    end
    % if data not found, move back some more and reloop
    fseek(fid,-2*BLCK_SIZE+3,'cof');
end



%% close file
fclose(fid);

end
