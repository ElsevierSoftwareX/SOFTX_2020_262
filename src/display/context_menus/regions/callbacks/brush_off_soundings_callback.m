function brush_off_soundings_callback(~,~,select_plot,main_figure,rem_soundings,set_bad)

layer=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');
[trans_obj,idx_freq]=layer.get_trans(curr_disp);

r_tot=trans_obj.get_transceiver_range();

switch class(select_plot)
    case 'region_cl'
        idx_r=select_plot.Idx_r;
        idx_ping=select_plot.Idx_ping;
    otherwise
        idx_ping=round(nanmin(select_plot.XData)):round(nanmax(select_plot.XData));
        idx_r=round(nanmin(select_plot.YData)):round(nanmax(select_plot.YData));
end

n=2;
if ~rem_soundings
    ping_tot=trans_obj.get_transceiver_pings();
    idx_ping_inter=intersect(ping_tot,idx_ping(1)-n:idx_ping(end)+n); 
    [~,idx_com]=intersect(idx_ping_inter,idx_ping);
else
   idx_ping_inter=idx_ping; 
   idx_com=1:numel(idx_ping);
end

bottom_idx=trans_obj.get_bottom_idx(idx_ping_inter);

idx_val=find((bottom_idx>=idx_r(1))&bottom_idx<=idx_r(end));
idx_brush=intersect(idx_ping_inter-idx_ping_inter(1)+1,idx_val);

bottom_idx(intersect(idx_brush,idx_com))=nan;

    [idx_alg,alg_found]=find_algo_idx(trans_obj,'BottomDetectionV2');
    
    
    if alg_found
        varin=trans_obj.Algo(idx_alg).input_params_to_struct();
        interp_method=varin.interp_method;
    else
        interp_method='Linear';
    end
    
    
    if ~rem_soundings
        bottom_idx=fillmissing(bottom_idx,interp_method);
    end
    
    bottom_idx=round(bottom_idx);

old_bot=trans_obj.Bottom;
bot=old_bot;

bot.Sample_idx(idx_ping_inter)=bottom_idx;
bot.Sample_idx(bot.Sample_idx<=1|bot.Sample_idx>numel(r_tot))=nan;

if set_bad>0
    bot.Tag(idx_brush+idx_ping_inter(1)-1)=0;
end

trans_obj.Bottom=bot;

curr_disp.Bot_changed_flag=1;


add_undo_bottom_action(main_figure,trans_obj,old_bot,bot);

display_bottom(main_figure);
set_alpha_map(main_figure,'update_bt',set_bad);
update_info_panel([],[],1);
end