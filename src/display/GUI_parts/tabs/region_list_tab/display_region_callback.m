function display_region_callback(~,~,main_figure,opt)
layer=get_current_layer();

if isempty(layer)
    return;
end

curr_disp=get_esp3_prop('curr_disp');

[trans_obj,~]=layer.get_trans(curr_disp);
load_bar_comp=getappdata(main_figure,'Loading_bar');

for i=1:length(curr_disp.Active_reg_ID)
    
    reg_curr=trans_obj.get_region_from_Unique_ID(curr_disp.Active_reg_ID{i});
    
    if isempty(reg_curr)
        return;
    end
    switch opt
        case '2D'
            
            switch reg_curr.Reference
                case 'Line'
                    line_obj=layer.get_first_line();
                otherwise
                    line_obj=[];
            end
            
            if ismember('svdenoised',trans_obj.Data.Fieldname)
                field='svdenoised';
            else
                field='sv';
            end
            show_status_bar(main_figure);
            
            reg_curr.display_region(trans_obj,'main_figure',main_figure,'line_obj',line_obj,'field',field,'load_bar_comp',load_bar_comp);
            
            hide_status_bar(main_figure);
        case '3D'
            reg_curr.display_region_3D(trans_obj,[],'main_figure',main_figure,'field','sp','load_bar_comp',load_bar_comp);
         case '3D_sv'
            reg_curr.display_region_3D(trans_obj,[],'main_figure',main_figure,'field','sv','load_bar_comp',load_bar_comp);
        case '3D_ST'
            reg_curr.display_region_3D(trans_obj,[],'main_figure',main_figure,'field','singletarget','load_bar_comp',load_bar_comp);
        case '3D_tracks'
            reg_curr.display_region_3D(trans_obj,[],'main_figure',main_figure,'field','singletarget','trackedOnly',1,'load_bar_comp',load_bar_comp);
    end
end
end