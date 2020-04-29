function add_survey_data_db(layers)

for ilay=1:length(layers)
    	surv_data={};
        [start_time,end_time]=layers(ilay).get_time_bound_files();
    for ifi=1:length(layers(ilay).Filename)
        if isfile(layers(ilay).Filename{ifi})
            surv_data_temp=get_file_survey_data_from_db(layers(ilay).Filename{ifi},start_time(ifi),end_time(ifi));
            surv_data=[surv_data surv_data_temp];
        end
    end
    
    layers(ilay).set_survey_data(surv_data);
end

end