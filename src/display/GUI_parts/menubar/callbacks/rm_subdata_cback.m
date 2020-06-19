function rm_subdata_cback(~,~,main_figure,field)

layer=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');
trans_obj=layer.get_trans(curr_disp);


switch field
    case 'denoised'
        fields={'powerdenoised' 'svdenoised' 'snr' 'spdenoised'};
        trans_obj.Data.remove_sub_data(fields);
        curr_disp.setField('sv');
    case 'st'
        trans_obj.ST=init_st_struct();
        trans_obj.Tracks=[];
        fields={'singletarget'};
        if~isempty(layer.Curves)
            layer.Curves(contains({layer.Curves(:).Unique_ID},'track'))=[];
        end
        update_st_tracks_tab(main_figure,'histo',1,'st',1);
        update_multi_freq_disp_tab(main_figure,'ts_f',1);
        trans_obj.Data.remove_sub_data(fields);
        display_tracks(main_figure);
        curr_disp.setField('sv');
end




end