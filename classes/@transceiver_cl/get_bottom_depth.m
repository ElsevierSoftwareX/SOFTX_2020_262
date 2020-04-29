function bot_depth=get_bottom_depth(trans_obj,varargin)

t_angle = trans_obj.get_transducer_pointing_angle();
bot_depth = trans_obj.get_bottom_range(varargin{:})*sin(t_angle) + trans_obj.get_transducer_depth(varargin{:});


    