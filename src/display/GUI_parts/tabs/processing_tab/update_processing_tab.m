function update_processing_tab(main_figure)

layer=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');
processing_tab_comp=getappdata(main_figure,'Processing_tab');
process_list=get_esp3_prop('process');
[trans_obj,idx_freq]=layer.get_trans(curr_disp);

set(processing_tab_comp.tog_freq,'String',num2str(layer.Frequencies'/1e3,'%.0f kHz'),'Value',idx_freq);

if ~isempty(process_list)
    [~,~,noise_rem_algo]=find_process_algo(process_list,curr_disp.Freq,'Denoise');

    [~,~,bot_algo]=find_process_algo(process_list,curr_disp.Freq,'BottomDetection');

    [~,~,bot_algo_v2]=find_process_algo(process_list,curr_disp.Freq,'BottomDetectionV2');

    [~,~,sp_algo]=find_process_algo(process_list,curr_disp.Freq,'SpikesRemoval');
    
    [~,~,bad_trans_algo]=find_process_algo(process_list,curr_disp.Freq,'BadPingsV2');

    [~,~,school_detect_algo]=find_process_algo(process_list,curr_disp.Freq,'SchoolDetection');

    [~,~,single_target_alg]=find_process_algo(process_list,curr_disp.Freq,'SingleTarget');

    [~,~,track_target_alg]=find_process_algo(process_list,curr_disp.Freq,'TrackTarget');

else
    
    noise_rem_algo=0;
    
    sp_algo = 0;
    
    bot_algo = 0;
    
    bot_algo_v2=0;
    
    bad_trans_algo=0;
    
    school_detect_algo=0;
    
    single_target_alg=0;
    
    track_target_alg=0;
end

set(processing_tab_comp.noise_removal,'Value',noise_rem_algo);
set(processing_tab_comp.spikes_removal,'Value',sp_algo);
set(processing_tab_comp.bot_detec,'Value',bot_algo);
set(processing_tab_comp.bot_detec_v2,'Value',bot_algo_v2);
set(processing_tab_comp.bad_transmit,'Value',bad_trans_algo);
set(processing_tab_comp.school_detec,'Value',school_detect_algo);
set(processing_tab_comp.single_target,'Value',single_target_alg);
set(processing_tab_comp.track_target,'Value',track_target_alg);

%set(findobj(processing_tab_comp.processing_tab, '-property', 'Enable'), 'Enable', 'on');

setappdata(main_figure,'Processing_tab',processing_tab_comp);

end