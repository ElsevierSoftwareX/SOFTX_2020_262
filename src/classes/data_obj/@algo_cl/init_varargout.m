function init_varargout(obj)

switch obj.Name
    case {'BottomDetectionV2','BottomDetection'}
        obj.Varargout={'bottom','bs_bottom','idx_ringdown','idx_pings','done'};
    case 'DropOuts'
        obj.Varargout={'idx_noise_sector','done'};
    case 'BadPingsV2'
        obj.Varargout={'idx_noise_sector','done'};
    case 'SpikesRemoval'
        obj.Varargout={'done'};
    case 'Denoise'
        obj.Varargout={'done'};
    case 'SchoolDetection'
        obj.Varargout={'linked_candidates','done'};
    case 'SingleTarget'
        obj.Varargout={'single_targets','done'};
    case 'TrackTarget'
        obj.Varargout={'tracks','done'};
    case 'BottomFeatures'
        obj.Varargout={'E1','E2','done'};
    case 'Classification'
        obj.Varargout={'school_struct' 'out_type' 'done'};        
    otherwise
        obj.Varargout={};     
end

end