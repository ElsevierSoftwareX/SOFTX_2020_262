function app_path=read_config_path_xml(xml_file)    
    xml_struct=parseXML(xml_file);
    app_node=get_childs(xml_struct,'AppPath');
    app_path_file=get_node_att(app_node);
    
    app_path=app_path_create();
    prop_file=fieldnames(app_path_file);
    
    for iprop =1:numel(prop_file)
        if isfield(app_path,prop_file{iprop})
            app_path.(prop_file{iprop}).Path_to_folder=app_path_file.(prop_file{iprop});
        end
    end
end