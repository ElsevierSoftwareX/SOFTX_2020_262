
function  save_cal_to_xml(cal,file_cal)

docNode = com.mathworks.xml.XMLUtils.createDocument('Root');
main_node=docNode.getDocumentElement;
main_node.setAttribute('Version','1.0');%

de_node = docNode.createElement('Description');

main_node.appendChild(de_node);
cal_node = docNode.createElement('Calibration');

cal_res_node = docNode.createElement('CalibrationResults');

fields = fieldnames(cal);

for iic=1:length(fields)
    tmp_node = docNode.createElement(fields{iic});
    tmp_node.appendChild(docNode.createTextNode(strjoin(cellfun(@num2str,num2cell(cal.(fields{iic})),'un',0),';')));
    cal_res_node.appendChild(tmp_node);
end

cal_node.appendChild(cal_res_node);
main_node.appendChild(cal_node);

xmlwrite(file_cal,docNode);
disp_perso([],sprintf('Calibration results saved to %s',file_cal));
end



