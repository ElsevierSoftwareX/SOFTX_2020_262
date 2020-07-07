function replace_sub_data_v2(data_obj,field,data_mat,idx_r,idx_pings)

if isempty(data_mat)
    return;
end
[idx,found]=find_field_idx(data_obj,field);
[fields,~,fmt_fields,factor_fields,default_values]=init_fields();

idx_field=strcmpi(field,fields);

if ~any(idx_field)&&contains(lower(field),'khz')
    idx_field=contains(fields,'khz');
end

default_value=default_values(idx_field);

if found==0
    data_obj.init_sub_data(field,default_value);
    [idx,~]=find_field_idx(data_obj,field);
end
nb_pings=data_obj.get_nb_pings_per_block();
nb_samples=data_obj.Nb_samples;

if numel(data_mat)>1
    [data_mat_cell,idx_r_cell,idx_pings_cell]=divide_mat_v2(data_mat,nb_samples,nb_pings,idx_r,idx_pings);
    
    for ii=1:length(data_mat_cell)
        if ~isempty(idx_pings_cell{ii})&&~isempty(idx_r_cell{ii})
            nb_samples_data=size(data_obj.SubData(idx).Memap{ii}.Data.(lower(deblank(field))),1);
            nb_samples_data_cell=size(data_mat_cell{ii},1);
            
            idx_r=idx_r_cell{ii};
            idx_r(idx_r_cell{ii}>nb_samples_data)=[];
            idx_r((idx_r-idx_r(1)+1)>nb_samples_data_cell)=[];
            idx_r_data=idx_r-idx_r(1)+1;
            
            data_obj.SubData(idx).Memap{ii}.Data.(lower(deblank(field)))(idx_r,idx_pings_cell{ii})=data_mat_cell{ii}(idx_r_data,:)/data_obj.SubData(idx).ConvFactor;
        end
        data_mat_cell{ii}=[];
    end
else
    for ii=1:length(nb_samples)
        data_obj.SubData(idx).Memap{ii}.Data.(lower(deblank(field)))(:)=data_mat/data_obj.SubData(idx).ConvFactor;
    end
    
end
end
