function update_curr_disp(curr_disp_obj,filepath)
    
    lim_att = get_lim_config_att();
    [display_config_file,~,~]=get_config_files();
    [~,fname,fext]=fileparts(display_config_file);
    
    disp_config_file=fullfile(filepath,[fname fext]);
    
    if isfile(disp_config_file)
        curr_disp_new=read_config_display_xml(disp_config_file);
        props=properties(curr_disp_obj);
        
        for i=1:numel(props)
            if ismember((props{i}),lim_att)
                curr_disp_obj.(props{i})=curr_disp_new.(props{i});
            end
        end
    end