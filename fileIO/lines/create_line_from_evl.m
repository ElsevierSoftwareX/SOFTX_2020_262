function obj=create_line_from_evl(filename)

[timestamp,depth]=read_evl(filename);
fprintf('\nLine file starts at %s and finishes at %s\n',datestr(timestamp(1)),datestr(timestamp(end)));
obj=line_cl('Tag','Imported from EVL','Range',depth,'Time',timestamp,'File_origin',{filename});
end