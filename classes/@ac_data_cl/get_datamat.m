function [datamat,idx]=get_datamat(data,field)

[idx,~]=find_field_idx(data,(deblank(field)));

datamat=get_subdatamat(data,[],[],'field',field);

end