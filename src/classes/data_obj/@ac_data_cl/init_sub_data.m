function init_sub_data(data_obj,field,default_value)

if ~iscell(field)
    field={field};
end

for i=1:length(field)
    fieldname=field{i};
    data_obj.remove_sub_data(fieldname);    
    nb_pings=data_obj.get_nb_pings_per_block();
    nb_samples=data_obj.Nb_samples;
    nb_beams=data_obj.Nb_beams;
    
    data_mat_size=cell(1,numel(nb_pings));
 
    for ifi=1:numel(nb_pings)
        if nb_beams(ifi)>1
            data_mat_size{ifi}=[nb_samples(ifi) nb_beams(ifi) nb_pings(ifi)];
        else
            data_mat_size{ifi}=[nb_samples(ifi) nb_pings(ifi)];
        end
    end
    
    new_sub_data=sub_ac_data_cl('field',fieldname,'memapname',data_obj.MemapName,'data',data_mat_size,'default_value',default_value);
    data_obj.SubData=[data_obj.SubData new_sub_data]; 
    data_obj.Fieldname=[data_obj.Fieldname {new_sub_data.Fieldname}];
    data_obj.Type=[data_obj.Type {new_sub_data.Type}];

end


end