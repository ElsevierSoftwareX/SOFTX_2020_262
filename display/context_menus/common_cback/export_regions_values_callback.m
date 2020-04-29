function export_regions_values_callback(~,~,main_figure,regs,field)

layer=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');
[trans_obj,idx_freq]=layer.get_trans(curr_disp);
inter_only=0;
echo_str='_regions';
switch regs
    case 'selected'
        reg_curr=trans_obj.get_region_from_Unique_ID(curr_disp.Active_reg_ID);
    case 'all'
        reg_curr=trans_obj.Regions;
        if isempty(regions)
            return;
        end
    case 'wc'
        reg_curr=trans_obj.create_WC_region(...
            'y_min',-inf,...
            'y_max',Inf,...
            'Type','Data',...
            'Ref','Transducer',...
            'Cell_w',1,...
            'Cell_h',1,...
            'Cell_w_unit','meters',...
            'Cell_h_unit','meters');
        echo_str='_WC';
    case 'wc_inter'
        reg_curr=trans_obj.create_WC_region(...
            'y_min',0,...
            'y_max',Inf,...
            'Type','Data',...
            'Ref','Transducer',...
            'Cell_w',1,...
            'Cell_h',1,...
            'Cell_w_unit','meters',...
            'Cell_h_unit','meters');
        inter_only=1;
        echo_str='_WC';
end


[path_tmp,~,~]=fileparts(layer.Filename{1});
layers_Str=list_layers(layer,'nb_char',80);
switch field
    case 'curr_data'
        field=curr_disp.Fieldname;
end

[fileN, pathname] = uiputfile({'*.xlsx'},...
    'Save regions to file',...
    fullfile(path_tmp,[layers_Str{1} echo_str '_' field '.xlsx']));

if isequal(pathname,0)||isequal(fileN,0)
    return;
end



show_status_bar(main_figure);
load_bar_comp=getappdata(main_figure,'Loading_bar');
if ~isempty(load_bar_comp)
    set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',numel(reg_curr), 'Value',0);
    load_bar_comp.progress_bar.setText('Exporting Regions Sv Values');
end

for i=1:numel(reg_curr)
    
    [~,fname,ext_f]=fileparts(fileN);
    file=fullfile(pathname,[fname '_' reg_curr(i).Name '_' num2str(reg_curr(i).ID) ext_f]);
    layer.export_region_values_to_xls(reg_curr(i),'output_f',file,'idx_freq',idx_freq,'idx_freq_end',idx_freq,'field',field,'intersection_only',inter_only);
    if ~isempty(load_bar_comp)
        set(load_bar_comp.progress_bar,'Value',i);
    end
end

hide_status_bar(main_figure);

end