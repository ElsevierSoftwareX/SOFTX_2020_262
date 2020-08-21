function [datamat,idx]=get_datamat(data_obj,field)

[idx,~]=data_obj.find_field_idx((deblank(field)));

datamat=data_obj.get_subdatamat('field',field);

end