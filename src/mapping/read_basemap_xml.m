function basemaps=read_basemap_xml(xml_file)
xml_struct=parseXML(xml_file);
basemaps_nodes=get_childs(xml_struct,'Basemap');
basemaps=[];
for it=1:numel(basemaps_nodes)
    tmp=get_node_att(basemaps_nodes(it));
    fields=fieldnames(tmp);
    for ifield=1:numel(fields)
        basemaps(it).(fields{ifield})=tmp.(fields{ifield});
    end
end
end