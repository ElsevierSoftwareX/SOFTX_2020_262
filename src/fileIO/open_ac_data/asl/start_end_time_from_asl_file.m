function [start_time,end_time]=start_end_time_from_asl_file(filename)
fid=fopen(filename,'r','b');

BLCK_SIZE=1e4;

if fid==-1
    start_time=0;
    end_time=1e9;
    return;
end
start_time=0;
end_time=1e9;

fseek(fid,0,'bof');
found_start=0;

while found_start==0&&~feof(fid)
    
    pos = ftell(fid);
    
    int_read=fread(fid,BLCK_SIZE,'uint16');
    idx_dg=find(int_read==hex2dec('FD02'));
    if ~isempty(idx_dg)
        found_start=1;
        
        for ui=idx_dg'
            idx_start=pos+2*(ui-1);
            fseek(fid,idx_start,'bof');
            fread(fid,6,'uint16');
            time=fread(fid,7,'uint16');
            
            
            tmp=datenum(time(1:6)')+time(end)/100/60/60/24;
            if numel(tmp)==1&&tmp<=now
                start_time=tmp;
                found_start=1;
                break;
            end
        end
    end

end



%% find end time in file

fseek(fid,0,'eof');
pos = ftell(fid);
BLCK_SIZE = nanmin(pos/2,1e6);
fseek(fid,-2*BLCK_SIZE,'cof');
found_end=0;


while found_end==0&&pos>0  
    
    pos=ftell(fid);
    int_read=fread(fid,BLCK_SIZE*2,'uint16');
    
    idx_dg=find(int_read==hex2dec('FD02'));
    
    if ~isempty(idx_dg)
        for ui=numel(idx_dg):-1:1
            idx_end=pos+(idx_dg(ui)-1)*2;
            
            fseek(fid,idx_end,'bof');
            fread(fid,6,'uint16');
            time=fread(fid,7,'uint16');
            
            tmp=datenum(time(1:6)')+time(end)/100/60/60/24;
            if numel(tmp)==1&&tmp>start_time&&tmp<=now
                end_time=tmp;
                found_end=1;
                break;
            end
        end
    end
    
    fseek(fid,-BLCK_SIZE*4,'cof');
    
end




fclose(fid);

end

