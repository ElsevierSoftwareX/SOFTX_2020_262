
function freq_response_reg_callback(src,evt,select_plot,main_figure,field,sliced)
layer=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');
[trans_obj,idx_freq]=layer.get_trans(curr_disp);

load_bar_comp=getappdata(main_figure,'Loading_bar');

switch class(select_plot)
    case 'region_cl'
        reg_obj=trans_obj.get_region_from_Unique_ID(curr_disp.Active_reg_ID);
    otherwise
        idx_pings=round(nanmin(select_plot.XData)):round(nanmax(select_plot.XData));
        idx_r=round(nanmin(select_plot.YData)):round(nanmax(select_plot.YData));        
        reg_obj=region_cl('Name','Select Area','Idx_r',idx_r,'Idx_pings',idx_pings,'Unique_ID','select_area');
end


show_status_bar(main_figure);
for i=1:length(reg_obj)    
    if~isempty(layer.Curves)
        layer.Curves(cellfun(@(x) strcmp(x,reg_obj(i).Unique_ID),{layer.Curves(:).Unique_ID}))=[];
    end
    %update_multi_freq_disp_tab(main_figure,'ts_f',0);
    switch(field)
        case {'sp','spdenoised','spunmatched'}
            
            layer.TS_freq_response_func('reg_obj',reg_obj(i),'load_bar_comp',load_bar_comp,'idx_freq',idx_freq);
            update_multi_freq_disp_tab(main_figure,'ts_f',0);
        case {'sv','svdenoised','svunmatched'}
            layer.Sv_freq_response_func('reg_obj',reg_obj(i),'sliced',sliced,'load_bar_comp',load_bar_comp,'idx_freq',idx_freq);
            update_multi_freq_disp_tab(main_figure,'sv_f',0);
        otherwise
            
            layer.TS_freq_response_func('reg_obj',reg_obj(i),'lbar',true,'load_bar_comp',load_bar_comp,'idx_freq',idx_freq);
            update_multi_freq_disp_tab(main_figure,'ts_f',0);
    end
end
hide_status_bar(main_figure);

end