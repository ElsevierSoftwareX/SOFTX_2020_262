function add_ts_curves_from_st_cback(~,~,main_figure)
curr_disp=get_esp3_prop('curr_disp');
layer=get_current_layer();
[trans_obj,~]=layer.get_trans(curr_disp);

if~isempty(layer.Curves)    
    layer.Curves(contains({layer.Curves(:).Name},'Single Target'))=[];
end

ST = trans_obj.ST;
if isempty(ST.idx_r)
    return;
end

TS_freq_response_func(main_figure,ST,true) ;

update_multi_freq_disp_tab(main_figure,'ts_f',0);
end
