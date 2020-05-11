function init_func(obj)

name=obj.Name;

switch name
    case 'BottomDetection'
        obj.Function=@detec_bottom_algo_v3;
    case 'BottomDetectionV2'
        obj.Function=@detec_bottom_algo_v4;
    case 'BadPingsV2'
        obj.Function=@bad_pings_removal_3;
    case 'DropOuts'
        obj.Function=@dropouts_detection;
    case 'Denoise'
        obj.Function=@bg_noise_removal_v2;
    case 'SchoolDetection'
        obj.Function=@school_detect;
    case 'SingleTarget'
        obj.Function=@single_targets_detection;
    case 'TrackTarget'
        obj.Function=@track_targets_angular;
    case 'SpikesRemoval'
        obj.Function=@spike_removal;
    case 'BottomFeatures'
        obj.Function=@compute_bottom_features;
    case 'Classification'
        obj.Function=@apply_classification;
    otherwise
        obj.Function=[];
        
end

end