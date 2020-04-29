function [idx,found]=find_field_idx(data,field)
idx=[];
if ~isempty(data)&&~isempty(data.Fieldname)
    idx=find(strcmpi(data.Fieldname,deblank(field)),1);
end
if isempty(idx)
    idx=1;
    found=0;
else
    found=1;
end

end