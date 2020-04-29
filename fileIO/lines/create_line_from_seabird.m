function obj=create_line_from_seabird(filename)

    [~,~,depth,~,timestamp,~]=read_seabird(filename);
    if isempty(depth)
        obj=[];
        return; 
    end
    fprintf('\nLine file starts at %s and finishes at %s\n',datestr(timestamp(1)),datestr(timestamp(end)));
    obj=line_cl('Tag','Imported from Seabird','Range',depth,'Time',timestamp-12/24,'File_origin',{filename},'UTC_diff',-12);
end