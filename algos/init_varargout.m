function varout=init_varargout(name)

switch name
    case {'BottomDetectionV2','BottomDetection'}
        varout={'bottom','bs_bottom','idx_ringdown','idx_pings','done'};
    case 'DropOuts'
        varout={'idx_noise_sector','done'};
    case 'BadPingsV2'
        varout={'idx_noise_sector','done'};
    case 'SpikesRemoval'
        varout={'done'};
    case 'Denoise'
        varout={'done'};
    case 'SchoolDetection'
        varout={'linked_candidates','done'};
    case 'SingleTarget'
        varout={'single_targets','done'};
    case 'TrackTarget'
        varout={'tracks','done'};
    case 'BottomFeatures'
        varout={'E1','E2','done'};
    case 'Classification'
        varout={'school_struct' 'out_type' 'done'};        
    otherwise
        varout={};
        
end

end