function export_regions_xyz_callback(src,~,main_figure,field)

layer=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');

[trans_obj,idx_freq]=layer.get_trans(curr_disp);
reg_curr=trans_obj.get_region_from_Unique_ID(curr_disp.Active_reg_ID);
[path_tmp,~,~]=fileparts(layer.Filename{1});

cax=curr_disp.getCaxField('sp');

[fileN, pathname] = uiputfile({'*.xyz' 'XYZ file';'*.vrml', 'VRML file'},...
    'Save region(s) echoes to XYZ or VRML format',...
    fullfile(path_tmp,'region_echoes.xyz'));
if isequal(pathname,0)||isequal(fileN,0)
    return;
end

switch field
    case 'curr_data'
        field=curr_disp.Fieldname;
end

file=fullfile(pathname,fileN);
switch src.Tag
    case 'all'
        layer.export_region_echoes_to_xyz(reg_curr,'field',field,'output_f',file,'idx_freq',idx_freq,'idx_freq_end',[],'thr',cax(1),'cmap',curr_disp.Cmap);
    otherwise
        layer.export_region_echoes_to_xyz(reg_curr,'field',field,'output_f',file,'idx_freq',idx_freq,'idx_freq_end',idx_freq,'thr',cax(1),'cmap',curr_disp.Cmap);
end

end