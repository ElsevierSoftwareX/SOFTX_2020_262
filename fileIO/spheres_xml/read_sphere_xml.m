function spheres=read_sphere_xml(xml_file)
xml_struct=parseXML(xml_file);
shperes_nodes=get_childs(xml_struct,'Sphere');
spheres=[];
for it=1:numel(shperes_nodes)
    tmp=get_node_att(shperes_nodes(it));
    fields=fieldnames(tmp);
    for ifield=1:numel(fields)
        spheres(it).(fields{ifield})=tmp.(fields{ifield});
    end
end
end