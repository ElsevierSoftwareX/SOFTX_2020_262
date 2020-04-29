function obj=create_line_from_xls(filename)
    opts = detectImportOptions(filename);
    data_struct =  readtable(filename,opts);
    
    fields =data_struct.Properties.VariableNames;
    
    if ~ismember('Depth',fields)
        obj=[];
        return; 
    end
    if isfield(data_struct,'Timestamp')
        time=datenum(data_struct.Timestamp);
    elseif isfield(data_struct,'Time')
        time=datenum(data_struct.Time);
    else        
       obj=[];
       return;
    end
    
    fprintf('\nLine file starts at %s and finishes at %s\n',datestr(time(1)),datestr(time(end)));
    obj=line_cl('Tag','Imported from XLS file','Range',abs(data_struct.Depth),'Time',time,'File_origin',{filename},'UTC_diff',0,'Data',data_struct.Temperature);
end