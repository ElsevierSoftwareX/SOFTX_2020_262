function init_func_and_descr(obj)

name=obj.Name;

switch name
    case 'BottomDetection'
        obj.Function=@detec_bottom_algo_v3;
        obj.Description = 'Detection of the bottom echo';
    case 'BottomDetectionV2'
        obj.Function=@detec_bottom_algo_v4;
        obj.Description = 'Detection of the bottom echo';
    case 'BadPingsV2'
        obj.Function=@bad_pings_removal_3;
        obj.Description = 'Automated detection of pings deemed unusable for further analysis and based on multiple criteria.';
    case 'DropOuts'
        obj.Function=@dropouts_detection;
        obj.Description = 'Detection of drops in signal level from consecutive pings, flagging them as “bad”.';
    case 'Denoise'
        obj.Function=@bg_noise_removal_v2;
        obj.Description = 'Removal of background noise and estimation of signal to noise ratio.';
    case 'SchoolDetection'
        obj.Function=@school_detect;
        obj.Description = 'Implementation of the shoal analysis and patch estimation system algorithm (SHAPES).';
    case 'SingleTarget'
        obj.Function=@single_targets_detection;
        obj.Description = 'Detection of isolated targets based on signal characteristics.';
    case 'TrackTarget'
        obj.Function=@track_targets_angular;
        obj.Description = 'Tracking of single targets in 4 dimensions.';
    case 'SpikesRemoval'
        obj.Function=@spike_removal;
        obj.Description = 'Automated detection of short bursts of noise attributed to external interferences and removed from further analysis.';
    case 'BottomFeatures'
        obj.Function=@compute_bottom_features;
        obj.Description = 'Calculation of RoxAnn bottom features “roughness (E1)” and “hardness (E2)”. Three approaches available.';
    case 'Classification'
        obj.Function=@apply_classification;
        obj.Description = 'Classification of regions or integration cells based on a user-defined classification tree.';
    otherwise
        obj.Function=[];
        obj.Description = '';
        
end

end