function [E1,E2] = get_bottom_features(trans_obj,varargin)

if nargin>=2
    idx_pings = varargin{1};
    if ~isempty(idx_pings)
        E1 = trans_obj.Bottom.E1(idx_pings);
        E2 = trans_obj.Bottom.E2(idx_pings);
    else
        E1 = trans_obj.Bottom.E1;
        E2 = trans_obj.Bottom.E2;
    end
else
    E1 = trans_obj.Bottom.E1;
    E2 = trans_obj.Bottom.E2;
end


end
