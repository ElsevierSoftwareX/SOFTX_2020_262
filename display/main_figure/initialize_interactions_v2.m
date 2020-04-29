
%% initialize_interactions_v2.m
%
% Initialize user interactions with ESP3 main figure, new version, in
% developpement
%
%% Help
%
% *USE*
%
% TODO
%
% *INPUT VARIABLES*
%
% * |main_figure|: Handle to main ESP3 window (Required).
% * |new|: Flag for refreshing or first time load (Required. |0| if
% refreshing or |1| if first-time loading).
%
% *OUTPUT VARIABLES*
%
% NA
%
% *RESEARCH NOTES*
%
% TODO
%
% *NEW FEATURES*
%
% * 2017-04-25: first version (Yoann Ladroit)
%
% *EXAMPLE*
%
% TODO
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function initialize_interactions_v2(main_figure)

interactions=remove_interactions(main_figure);

%%% Set Interactions

% Pointer to Arrow
setptr(main_figure,'arrow');

% Initialize Mouse interactions in the figure
interactions.WindowButtonDownFcn(1)=iptaddcallback(main_figure,'WindowButtonDownFcn',{@select_area_cback,main_figure});

% Initialize Keyboard interactions in the figure
interactions.KeyPressFcn(1)=iptaddcallback(main_figure,'KeyPressFcn',{@keyboard_func,main_figure});

interactions.KeyReleaseFcn(1)=iptaddcallback(main_figure,'KeyPressFcn',{@reactivate_keyboard_func,main_figure});

% Set wheel mouse scroll cback
interactions.WindowScrollWheelFcn(1)=iptaddcallback(main_figure,'WindowScrollWheelFcn',{@scroll_fcn_callback,main_figure});

% Set pointer motion cback
%interactions.WindowButtonMotionFcn(1)=iptaddcallback(main_figure,'WindowButtonMotionFcn',{@update_info_panel,0});
%interactions.WindowButtonMotionFcn(3)=iptaddcallback(main_figure,'WindowButtonMotionFcn',{@update_boat_position,main_figure});

setappdata(main_figure,'interactions_id',interactions);
setptr(main_figure,'arrow');
end