
function freq_response_reg_callback(src,evt,select_plot,main_figure,field,sliced)
layer=get_current_layer();

switch class(select_plot)
    case 'region_cl'
        curr_disp=get_esp3_prop('curr_disp');
       
        [trans_obj,~]=layer.get_trans(curr_disp);

        reg_obj=trans_obj.get_region_from_Unique_ID(curr_disp.Active_reg_ID);
    otherwise
        idx_pings=round(nanmin(select_plot.XData)):round(nanmax(select_plot.XData));
        idx_r=round(nanmin(select_plot.YData)):round(nanmax(select_plot.YData));        
        reg_obj=region_cl('Name','Select Area','Idx_r',idx_r,'Idx_pings',idx_pings,'Unique_ID','select_area');
end




for i=1:length(reg_obj)
    
    if~isempty(layer.Curves)
        layer.Curves(cellfun(@(x) strcmp(x,reg_obj(i).Unique_ID),{layer.Curves(:).Unique_ID}))=[];
    end
    %update_multi_freq_disp_tab(main_figure,'ts_f',0);
    switch(field)
        case {'sp','spdenoised','spunmatched'}
            TS_freq_response_func(main_figure,reg_obj(i),true);
            update_multi_freq_disp_tab(main_figure,'ts_f',0);
        case {'sv','svdenoised','svunmatched'}
            Sv_freq_response_func(main_figure,reg_obj(i),sliced);
            update_multi_freq_disp_tab(main_figure,'sv_f',0);
        otherwise
            TS_freq_response_func(main_figure,reg_obj(i),true);
            update_multi_freq_disp_tab(main_figure,'ts_f',0);
    end
end

end