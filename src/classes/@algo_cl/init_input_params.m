
%% Function
function init_input_params(obj)

denoise_param = algo_param_cl('Name','denoised','Value',true,'Default_value',true,'Value_range',[true false],...
    'Precision','%d','Validation_fcn',@(x) islogical(x),'Disp_name','Denoised data','Tooltipstring','Apply algorithm on denoised data','Units','');

snr_filt_param = algo_param_cl('Name','snr_filt','Value',true,'Default_value',true,'Value_range',[true false],...
    'Precision','%d','Validation_fcn',@(x) islogical(x),'Disp_name','Filter SNR','Tooltipstring','Apply filter to the SNR (size as defined for the noise power estimation)','Units','');

cluster_param = algo_param_cl('Name','cluster_tags','Value',true,'Default_value',true,'Value_range',[true false],...
    'Precision','%d','Validation_fcn',@(x) islogical(x),'Disp_name','Cluster tags','Tooltipstring','Apply a clustering on tags','Units','');

thr_cluster_param=algo_param_cl('Name','thr_cluster','Value',10,'Default_value',10,'Value_range',[0 100],...
    'Precision','%g','Validation_fcn',@(x) isnumeric(x),'Disp_name','Cluster % thr.','Tooltipstring','Keep tags with a number of cells higher than the threshold, attributes them to the most probable tag otherwise','Units','%');

v_filt_param = algo_param_cl('Name','v_filt','Value',1.5,'Default_value',1.5,'Value_range',[0.1 100],...
    'Precision','%.1f','Validation_fcn',@(x)  isnumeric(x),'Disp_name','Vert. Filt.','Tooltipstring','Vertical filtering','Units','m');
h_filt_param = algo_param_cl('Name','h_filt','Value',10,'Default_value',10,'Value_range',[0.1 1e3],...
    'Precision','%.0f','Validation_fcn',@(x)  isnumeric(x),'Disp_name','Horz. Filt.','Tooltipstring','Horizontal filtering','Units','pings');

v_buff_param = algo_param_cl('Name','v_buffer','Value',2,'Default_value',1.5,'Value_range',[0.1 100],...
    'Precision','%.1f','Validation_fcn',@(x)  isnumeric(x),'Disp_name','Vert. Buffer','Tooltipstring','Vertical buffering','Units','m');

r_min_param = algo_param_cl('Name','r_min','Value',0,'Default_value',0,'Value_range',[-inf inf],...
    'Precision','%.1f','Validation_fcn',@(x) isnumeric(x),'Disp_name','Min. Range','Tooltipstring','Minimum range (from transducer face)','Units','m');
r_max_param =  algo_param_cl('Name','r_max','Value',inf,'Default_value',inf,'Value_range',[0 inf],...
    'Precision','%.1f','Validation_fcn',@(x) isnumeric(x),'Disp_name','Max. Range','Tooltipstring','Maximum range (from transducer face)','Units','m');
shift_bot_param = algo_param_cl('Name','shift_bot','Value',0,'Default_value',0,'Value_range',[-inf inf],...
    'Precision','%.1f','Validation_fcn',@(x)  isnumeric(x),'Disp_name','Shift bot.','Tooltipstring','Shift bottom after detection','Units','m');

thr_bottom_param = algo_param_cl('Name','thr_bottom','Value',-35,'Default_value',0,'Value_range',[-90 -10],...
    'Precision','%.0f','Validation_fcn',@(x) isnumeric(x),'Disp_name','BS. thr.','Tooltipstring','Threshold for bottom echo','Units','dB');
thr_echo_param = algo_param_cl('Name','thr_echo','Value',-12,'Default_value',0,'Value_range',[-90 -10],...
    'Precision','%.0f','Validation_fcn',@(x) isnumeric(x),'Disp_name','Echo thr.','Tooltipstring','Around Echo threshold','Units','dB');
thr_backstep_param = algo_param_cl('Name','thr_backstep','Value',-1,'Default_value',0,'Value_range',[-12 12],...
    'Precision','%.0f','Validation_fcn',@(x) isnumeric(x),'Disp_name','Back. thr.','Tooltipstring','Threshold for backstep','Units','dB');
thr_sv_param=algo_param_cl('Name','thr_sv','Value',-70,'Default_value',-70,'Value_range',[-120 -10],...
    'Precision','%.0f','Validation_fcn',@(x) isnumeric(x),'Disp_name','Sv thr. Min.','Tooltipstring','Minimum thresholding on Sv','Units','dB');

thr_sv_max_param = algo_param_cl('Name','thr_sv_max','Value',-35,'Default_value',-35,'Value_range',[-120 -10],...
    'Precision','%.0f','Validation_fcn',@(x) isnumeric(x),'Disp_name','Sv thr. Max.','Tooltipstring','Maximum thresholding on Sv','Units','dB');
thr_ts_param=algo_param_cl('Name','TS_threshold','Value',-65,'Default_value',-65,'Value_range',[-120 -10],...
    'Precision','%.0f','Validation_fcn',@(x) isnumeric(x),'Disp_name','TS thr. Min.','Tooltipstring','Minimum thresholding on TS','Units','dB');
thr_ts_max_param=algo_param_cl('Name','TS_threshold_max','Value',0,'Default_value',0,'Value_range',[-120 0],...
    'Precision','%.0f','Validation_fcn',@(x) isnumeric(x),'Disp_name','TS thr. Max.','Tooltipstring','Maximum thresholding on TS','Units','dB');

thr_sp_param=algo_param_cl('Name','thr_sp','Value',-70,'Default_value',-70,'Value_range',[-120 -10],...
    'Precision','%.0f','Validation_fcn',@(x) isnumeric(x),'Disp_name','Sp thr. Min.','Tooltipstring','Minimum thresholding on Sp','Units','dB');

% thr_sp_max_param = algo_param_cl('Name','thr_sp_max','Value',-35,'Default_value',-35,'Value_range',[-120 -10],...
%     'Precision','%.0f','Validation_fcn',@(x) isnumeric(x),'Disp_name','Sp thr. Max.','Tooltipstring','Maximum thresholding on S','Units','dB');


std_maj_angle_param = algo_param_cl('Name','MaxStdMajAxisAngle','Value',1,'Default_value',1,'Value_range',[0 20],...
    'Precision','%.1f','Validation_fcn',@(x)  isnumeric(x),'Disp_name',[char(hex2dec('0394')) ' Across Angle'],'Tooltipstring','Maximum stadard deviation of across postion','Units',char(hex2dec('00B0')));
std_min_angle_param = algo_param_cl('Name','MaxStdMinAxisAngle','Value',1,'Default_value',1,'Value_range',[0 20],...
    'Precision','%.1f','Validation_fcn',@(x)  isnumeric(x),'Disp_name',[char(hex2dec('0394')) ' Along Angle'],'Tooltipstring','Maximum stadard deviation of along postion','Units',char(hex2dec('00B0')));


thr_cum_min=algo_param_cl('Name','thr_cum','Value',1e-2,'Default_value',1e-2,'Value_range',[0 100],...
    'Precision','%g','Validation_fcn',@(x) isnumeric(x),'Disp_name','Cumul. thr. Min.','Tooltipstring','Minimum Cumulative threshold','Units','%');

thr_cum_max=algo_param_cl('Name','thr_cum_max','Value',99.999,'Default_value',99.999,'Value_range',[0 100],...
    'Precision','%g','Validation_fcn',@(x) isnumeric(x),'Disp_name','Cumul. thr. Max.','Tooltipstring','Maximum Cumulative threshold','Units','%');

reg_ref_params=algo_param_cl('Name','ref','Value','Surface','Default_value','Surface','Value_range',{'Surface' 'Transducer' 'Bottom'},...
    'Precision','%s','Validation_fcn',@(x) ismember(x,{'Surface' 'Transducer' 'Bottom'}),'Disp_name','Reference','Tooltipstring','Reference used for WC integration','Units','');

interp_methods={'None','Linear','Nearest','Next','Previous','Pchip','Spline','Makima'};
interp_params=algo_param_cl('Name','interp_method','Value','Linear','Default_value','Linear','Value_range',interp_methods,...
    'Precision','%s','Validation_fcn',@(x) ismember(x,interp_methods),'Disp_name','Interpolation method','Tooltipstring','Interpolation method used','Units','');


horz_link_max_param=algo_param_cl('Name','horz_link_max','Value',5,'Default_value',5,'Value_range',[0 inf],...
    'Precision','%.1f','Validation_fcn',@(x)  isnumeric(x),'Disp_name','Max. Horz. link','Tooltipstring','Maximum horizontal length school linking','Units','m');
vert_link_max_param=algo_param_cl('Name','vert_link_max','Value',5,'Default_value',5,'Value_range',[0 inf],...
    'Precision','%.1f','Validation_fcn',@(x)  isnumeric(x),'Disp_name','Max. Vert. link','Tooltipstring','Maximum vertical length school linking','Units','m');

l_min_tot_param=algo_param_cl('Name','l_min_tot','Value',10,'Default_value',10,'Value_range',[0 inf],...
    'Precision','%.1f','Validation_fcn',@(x)  isnumeric(x),'Disp_name','Tot. Min. Len','Tooltipstring','School minimum length','Units','m');
h_min_tot_param=algo_param_cl('Name','h_min_tot','Value',10,'Default_value',10,'Value_range',[0 inf],...
    'Precision','%.1f','Validation_fcn',@(x)  isnumeric(x),'Disp_name','Tot. Min. Hght','Tooltipstring','School minimum height','Units','m');


switch obj.Name
    case 'Classification'
        files_classif=list_classification_files();
        
        obj.Input_params=[...
            algo_param_cl('Name','classification_file','Value',files_classif{1},'Default_value',files_classif{1},'Value_range',files_classif,...
            'Precision','%s','Validation_fcn',@ischar,'Disp_name','Classification File','Tooltipstring','Classification file','Units','')...
            reg_ref_params...
            l_min_tot_param...
            h_min_tot_param...
            horz_link_max_param ...
            vert_link_max_param ...           
            thr_cluster_param...
            cluster_param... 
            algo_param_cl('Name','create_regions','Value',true,'Default_value',true,'Value_range',[true false],...
            'Precision','%d','Validation_fcn',@(x) islogical(x),'Disp_name','Create regions','Tooltipstring','Create regions after classifications (only for Cell by cell)','Units','')...
            algo_param_cl('Name','reslice','Value',true,'Default_value',true,'Value_range',[true false],...
            'Precision','%d','Validation_fcn',@(x) islogical(x),'Disp_name','Re-integrate','Tooltipstring','Re-compute echo-integration','Units','')...
            ];
        
        
    case 'BottomDetection'
        obj.Input_params=[...  
            r_min_param...
            r_max_param...
            thr_bottom_param...
            thr_backstep_param...
            h_filt_param...
            v_filt_param...
            shift_bot_param...
            interp_params...
            denoise_param...
            ];
        
    case 'BottomDetectionV2'
        obj.Input_params=[...          
            r_min_param...
            r_max_param...
            thr_bottom_param...
            thr_backstep_param...
            thr_echo_param...
            thr_cum_min...
            shift_bot_param...
            interp_params...
            denoise_param...
            ];
        
    case 'DropOuts'
        obj.Input_params=[...
            r_min_param...
            r_max_param...
            thr_sv_param...
            thr_sv_max_param...
            algo_param_cl('Name','gate_dB','Value',3,'Default_value',3,'Value_range',[0 40],...
            'Precision','%.1f','Validation_fcn',@(x) isnumeric(x),'Disp_name','Diff. thr.','Tooltipstring','Threshold on difference between pings','Units','dB')...
            ];
        
    case 'BadPingsV2'
        obj.Input_params=[...
            algo_param_cl('Name','Ringdown_std_bool','Value',true,'Default_value',true,'Value_range',[true false],...
            'Precision','%d','Validation_fcn',@(x) islogical(x),'Disp_name','Ringdown std thr.','Tooltipstring','Use Ringdown Analysis','Units','')...
            algo_param_cl('Name','Ringdown_std','Value',0.05,'Default_value',0,'Value_range',[0 inf],...
            'Precision','%.2f','Validation_fcn',@(x) isnumeric(x),'Disp_name','','Tooltipstring','Ringdown deviation threshold','Units','dB')...
            algo_param_cl('Name','BS_std_bool','Value',true,'Default_value',true,'Value_range',[true false],...
            'Precision','%.d','Validation_fcn',@(x)  islogical(x),'Disp_name','Bottom Echo std thr.','Tooltipstring','Use Bottom Echo Backscatter Analysis','Units','')...
            algo_param_cl('Name','BS_std','Value',9,'Default_value',9,'Value_range',[0 inf],...
            'Precision','%.0f','Validation_fcn',@(x) isnumeric(x),'Disp_name','','Tooltipstring','Bottom echo deviation threshold','Units','dB')...
            algo_param_cl('Name','Above','Value',true,'Default_value',true,'Value_range',[true false],...
            'Precision','%d','Validation_fcn',@(x) islogical(x),'Disp_name','Above bot. echo std thr.','Tooltipstring','Use Above Bottom Echo Backscatter Analysis','Units','')...
            algo_param_cl('Name','thr_spikes_Above','Value',3,'Default_value',3,'Value_range',[0 inf],...
            'Precision','%.0f','Validation_fcn',@(x) isnumeric(x),'Disp_name','','Tooltipstring','Above Bottom echo deviation threshold','Units','dB')...
            algo_param_cl('Name','Below','Value',false,'Default_value',false,'Value_range',[true false],...
            'Precision','%d','Validation_fcn',@(x) islogical(x),'Disp_name','Below bot. echo std thr.','Tooltipstring','Use Below Bottom Echo Backscatter Analysis','Units','')...
            algo_param_cl('Name','thr_spikes_Below','Value',3,'Default_value',3,'Value_range',[0 inf],...
            'Precision','%.0f','Validation_fcn',@(x) isnumeric(x),'Disp_name','','Tooltipstring','Below bottom echo deviation threshold','Units','dB')...
             algo_param_cl('Name','Additive','Value',true,'Default_value',true,'Value_range',[true false],...
            'Precision','%d','Validation_fcn',@(x) islogical(x),'Disp_name','Additive noise thr.','Tooltipstring','Use Additive Noise Filter','Units','')...
            algo_param_cl('Name','thr_add_noise','Value',-140,'Default_value',-140,'Value_range',[-inf 0],...
            'Precision','%.0f','Validation_fcn',@(x) isnumeric(x),'Disp_name','','Tooltipstring','Additive noise threshold','Units','dB')...
            denoise_param...
            ];
        
    case 'SpikesRemoval'
        obj.Input_params=[...
            r_min_param ...
            r_max_param ...
            algo_param_cl('Name','thr_spikes','Value',10,'Default_value',10,'Value_range',[0 50],...
            'Precision','%.0f','Validation_fcn',@(x) isnumeric(x),'Disp_name','Spikes thr.','Tooltipstring','Threshold for spike detection (prominence)','Units','dB')...
            thr_sp_param...
            v_filt_param...
            v_buff_param ...
            algo_param_cl('Name','flag_bad_pings','Value',100,'Default_value',100,'Value_range',[0 100],...
            'Precision','%d','Validation_fcn',@(x) isnumeric(x),'Disp_name','BP flag thr.','Tooltipstring','Bad Ping flag threshold (nothing removed if = 100)','Units','%')...
            denoise_param...
            ];
              
    case 'SchoolDetection'
        obj.Input_params=[...
            r_min_param...
            r_max_param...
            thr_sv_param...
            thr_sv_max_param...
            algo_param_cl('Name','l_min_can','Value',10,'Default_value',10,'Value_range',[0 inf],...
            'Precision','%.1f','Validation_fcn',@(x)  isnumeric(x),'Disp_name','Can. Min. Len','Tooltipstring','Candidate minimum length','Units','m')....
            algo_param_cl('Name','h_min_can','Value',10,'Default_value',10,'Value_range',[0 inf],...
            'Precision','%.1f','Validation_fcn',@(x)  isnumeric(x),'Disp_name','Can. Min. Hght','Tooltipstring','Candidate minimum height','Units','m')...
            l_min_tot_param...
            h_min_tot_param...
            horz_link_max_param ...
            vert_link_max_param ...
            algo_param_cl('Name','nb_min_sples','Value',100,'Default_value',5,'Value_range',[0 inf],...
            'Precision','%.1f','Validation_fcn',@(x)  isnumeric(x),'Disp_name','Min. sple number','Tooltipstring','Minimum number of samples in school','Units','')...
            denoise_param...
            ];
        
    case 'Denoise'
        obj.Input_params=[...
            h_filt_param...
            v_filt_param...
            algo_param_cl('Name','NoiseThr','Value',-125,'Default_value',-125,'Value_range',[-150 -50],...
            'Precision','%.0f','Validation_fcn',@(x)  isnumeric(x),'Disp_name','Noise Level thr.','Tooltipstring','Maximum background noise level','Units','dB')...
            algo_param_cl('Name','SNRThr','Value',10,'Default_value',10,'Value_range',[0 50],...
            'Precision','%.0f','Validation_fcn',@(x)  isnumeric(x),'Disp_name','SNR thr.','Tooltipstring','Minimum Signal to Noise Ratio','Units','dB')...
            snr_filt_param...
            ];
        
    case 'SingleTarget'
        obj.Input_params=[...           
            r_min_param...
            r_max_param...
            thr_ts_param...
            thr_ts_max_param...
            algo_param_cl('Name','PLDL','Value',6,'Default_value',6,'Value_range',[3 12],...
            'Precision','%.0f','Validation_fcn',@(x)  isnumeric(x),'Disp_name','PLDL','Tooltipstring','Pulse Length Determination Level','Units','dB')...
            algo_param_cl('Name','MaxBeamComp','Value',12,'Default_value',12,'Value_range',[0 20],...
            'Precision','%.0f','Validation_fcn',@(x)  isnumeric(x),'Disp_name','Max. BP. Corr.','Tooltipstring','Maximum Beam Pattern Correction','Units','dB')...
            algo_param_cl('Name','MinNormPL','Value',0.6,'Default_value',0.6,'Value_range',[0.1 1],...
            'Precision','%.1f','Validation_fcn',@(x)  isnumeric(x),'Disp_name','Min. Norm. PL','Tooltipstring','Minimum normalized pulse length','Units','')...
            algo_param_cl('Name','MaxNormPL','Value',1.2,'Default_value',1.2,'Value_range',[1 2],...
            'Precision','%.1f','Validation_fcn',@(x)  isnumeric(x),'Disp_name','Max. Norm. PL','Tooltipstring','Maximum normalized pulse length','Units','')...
            std_maj_angle_param...
            std_min_angle_param...
            denoise_param...
            ];
        
    case 'TrackTarget'
        obj.Input_params=[...
            algo_param_cl('Name','AlphaMajAxis','Value',0.3,'Default_value',0.3,'Value_range',[0 1],...
            'Precision','%.1f','Validation_fcn',@(x)  isnumeric(x),'Disp_name','Alpha Major','Tooltipstring','Alpha parameter for Major axis (across)','Units','')...
            algo_param_cl('Name','AlphaMinAxis','Value',0.3,'Default_value',0.3,'Value_range',[0 1],...
            'Precision','%.1f','Validation_fcn',@(x)  isnumeric(x),'Disp_name','Alpha Minor','Tooltipstring','Alpha parameter for Minor axis (along)','Units','')...
            algo_param_cl('Name','AlphaRange','Value',0.3,'Default_value',0.3,'Value_range',[0 1],...
            'Precision','%.1f','Validation_fcn',@(x)  isnumeric(x),'Disp_name','Alpha Range','Tooltipstring','Alpha parameter for range','Units','')...
            algo_param_cl('Name','BetaMajAxis','Value',0.3,'Default_value',0.3,'Value_range',[0 1],...
            'Precision','%.1f','Validation_fcn',@(x)  isnumeric(x),'Disp_name','Beta Major','Tooltipstring','Beta parameter for Major axis (across)','Units','')...
            algo_param_cl('Name','BetaMinAxis','Value',0.3,'Default_value',0.3,'Value_range',[0 1],...
            'Precision','%.1f','Validation_fcn',@(x)  isnumeric(x),'Disp_name','Beta Minor','Tooltipstring','Beta parameter for Minor axis (along)','Units','')...
            algo_param_cl('Name','BetaRange','Value',0.3,'Default_value',0.3,'Value_range',[0 1],...
            'Precision','%.1f','Validation_fcn',@(x)  isnumeric(x),'Disp_name','Beta Range','Tooltipstring','Beta parameter for range','Units','')...
            algo_param_cl('Name','ExcluDistMajAxis','Value',1,'Default_value',1,'Value_range',[0 inf],...
            'Precision','%.1f','Validation_fcn',@(x)  isnumeric(x),'Disp_name','Excl. Dist. Maj.','Tooltipstring','Exclusion distance in meters on major axis (across)','Units','m')...
            algo_param_cl('Name','ExcluDistMinAxis','Value',1,'Default_value',1,'Value_range',[0 inf],...
            'Precision','%.1f','Validation_fcn',@(x)  isnumeric(x),'Disp_name','Excl. Dist. Min.','Tooltipstring','Exclusion distance in meters on minor axis (along)','Units','m')....
            algo_param_cl('Name','ExcluDistRange','Value',1,'Default_value',1,'Value_range',[0 inf],...
            'Precision','%.1f','Validation_fcn',@(x)  isnumeric(x),'Disp_name','Excl. Dist. R.','Tooltipstring','Exclusion distance in meters on range','Units','m')....
            std_maj_angle_param...
            std_min_angle_param...
            algo_param_cl('Name','MissedPingExpMajAxis','Value',5,'Default_value',5,'Value_range',[0 100],...
            'Precision','%.0f','Validation_fcn',@(x)  isnumeric(x),'Disp_name','Missed Pings Exp. Maj.','Tooltipstring','Expansion of exclusion distance between pings on major axis (across)','Units','%')...
            algo_param_cl('Name','MissedPingExpMinAxis','Value',5,'Default_value',5,'Value_range',[0 100],...
            'Precision','%.0f','Validation_fcn',@(x)  isnumeric(x),'Disp_name','Missed Pings Exp. Min.','Tooltipstring','Expansion of exclusion distance between pings on minor axis (along)','Units','%')...
            algo_param_cl('Name','MissedPingExpRange','Value',5,'Default_value',5,'Value_range',[0 100],...
            'Precision','%.0f','Validation_fcn',@(x)  isnumeric(x),'Disp_name','Missed Pings Exp. R.','Tooltipstring','Expansion of exclusion distance between pings on range','Units','%')...
            algo_param_cl('Name','WeightMajAxis','Value',20,'Default_value',20,'Value_range',[0 100],...
            'Precision','%.0f','Validation_fcn',@(x)  isnumeric(x),'Disp_name','W. Maj.','Tooltipstring','Weight attributed to position on major axis (across)','Units','')...
            algo_param_cl('Name','WeightMinAxis','Value',20,'Default_value',20,'Value_range',[0 100],...
            'Precision','%.0f','Validation_fcn',@(x)  isnumeric(x),'Disp_name','W. Min.','Tooltipstring','Weight attributed to position on minor axis (along)','Units','')...
            algo_param_cl('Name','WeightRange','Value',40,'Default_value',40,'Value_range',[0 100],...
            'Precision','%.0f','Validation_fcn',@(x)  isnumeric(x),'Disp_name','W. R.','Tooltipstring','Weight attributed to position in range','Units','')...
            algo_param_cl('Name','WeightTS','Value',10,'Default_value',10,'Value_range',[0 100],...
            'Precision','%.0f','Validation_fcn',@(x)  isnumeric(x),'Disp_name','W. TS.','Tooltipstring','Weight attributed to TS value','Units','')...
            algo_param_cl('Name','WeightPingGap','Value',10,'Default_value',10,'Value_range',[0 100],...
            'Precision','%.0f','Validation_fcn',@(x)  isnumeric(x),'Disp_name','W. Ping Gap','Tooltipstring','Weight attributed to ping gap','Units','')...
            algo_param_cl('Name','Min_ST_Track','Value',3,'Default_value',3,'Value_range',[1 inf],...
            'Precision','%.0f','Validation_fcn',@(x)  isnumeric(x),'Disp_name','Min. ST','Tooltipstring','Minimum number of single targets in track','Units','')...
            algo_param_cl('Name','Min_Pings_Track','Value',5,'Default_value',5,'Value_range',[1 inf],...
            'Precision','%.0f','Validation_fcn',@(x)  isnumeric(x),'Disp_name','Min. Pings','Tooltipstring','Minimum number of pings in track','Units','')...
            algo_param_cl('Name','Max_Gap_Track','Value',2,'Default_value',2,'Value_range',[1 inf],...
            'Precision','%.0f','Validation_fcn',@(x)  isnumeric(x),'Disp_name','Max. Gaps','Tooltipstring','Maximum number of gaps in track)','Units','pings')...
            algo_param_cl('Name','IgnoreAttitude','Value',false,'Default_value',false,'Value_range',[true false],...
            'Precision','%d','Validation_fcn',@(x) islogical(x),'Disp_name','Ignore attitude','Tooltipstring','Ignore attitude data when computing angles and distances','Units','')...
            ];
        
    case 'BottomFeatures'
        obj.Input_params=[...
            algo_param_cl('Name','bot_feat_comp_method','Value','Echoview','Default_value','Echoview','Value_range',{'Echoview' 'Yoann' 'Rudy Kloser'},...
            'Precision','%s','Validation_fcn',@(x) ismember(x,{'Echoview' 'Yoann' 'Rudy Kloser'}),'Disp_name','Computation Method','Tooltipstring','Method used for bottom features (E1/E2) computation','Units','')...
            thr_cum_min...
            thr_cum_max...
            algo_param_cl('Name','estimated_slope','Value',5,'Default_value',5,'Value_range',[-90 90],...
            'Precision','%d','Validation_fcn',@(x) isnumeric(x),'Disp_name','Estimated slope','Tooltipstring','Estimated sleafloor slope','Units',char(hex2dec('00B0')))...
            thr_sv_param...
            algo_param_cl('Name','bot_ref_depth','Value',100,'Default_value',100,'Value_range',[1 inf],...
            'Precision','%.0f','Validation_fcn',@(x)  isnumeric(x),'Disp_name','Bot. Depth Ref.','Tooltipstring','Bottom depth used as reference','Units','m')....
            denoise_param...
            ];
    otherwise
        obj.Input_params=[];
        
end

end