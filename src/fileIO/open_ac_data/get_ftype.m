function ftype=get_ftype(filename)

if isfile(filename)>0
    
    [~,fname,end_file]=fileparts(filename);
    
    if strcmp(end_file,'.db')
        ftype='db';
       return; 
    end
    
    if strcmp(end_file,'.lst')||strcmp(end_file,'.ini')
        ftype='FCV30';
       return; 
    end

    if strcmp(end_file,'.ddf')
        ftype='DIDSON';
        return;
    end
    
    fid = fopen(filename, 'r');
    if fid==-1
        warndlg_perso([],'Failed',sprintf('Cannot open file %s',filename));
        ftype='invalid';
        return;
    end
    fread(fid,1, 'int32', 'l');
    [dgType, ~] =read_dgHeader(fid,0);    
    fclose(fid);
    
    switch dgType
        case 'XML0'
            ftype='EK80';
        case 'CON0'
            ftype='EK60';
        otherwise
            
            fid = fopen(filename,'r','b');
            dgType=fread(fid,1,'uint16');
            fclose(fid);
            
            fid = fopen(filename,'r','b');
            filePingNumber = fread(fid,1,'int16','b');
            TOPASformat = fread(fid,1,'int16','b');
            yr = fread(fid,1,'int16','b');
            mo = fread(fid,1,'int16','b');
            dy = fread(fid,1,'int16','b');
            hr = fread(fid,1,'int16','b');
            mi = fread(fid,1,'int16','b');
            sc = fread(fid,1,'int16','b');
            msc = fread(fid,1,'int16','b');
            
            pingTime = datenum(yr,mo,dy,hr,mi,sc+msc/1000);
            origFilename = fread(fid,16,'*char')';
            [~,origFilename,~]=fileparts(origFilename);
            fclose(fid);
            
            if hex2dec('FD02')==dgType
                ftype='ASL';
            elseif contains(filename,origFilename)
                ftype='TOPAS';
            else
                if fname(1)=='d'&&isempty(end_file)
                     ftype='CREST';
                else
                    ftype='Unknown';
                end
            end
            
    end
else
   ftype='Unknown'; 
end


end