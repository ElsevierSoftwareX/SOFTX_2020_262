%% init_java_fcn(main_figure).m
%
% TODO: write short description of function
%
%% Help
%
% *USE*
%
% TODO: write longer description of function
%
% *INPUT VARIABLES*
%
% * |input_variable_1|: TODO: write description and info on variable
%
% *OUTPUT VARIABLES*
%
% * |output_variable_1|: TODO: write description and info on variable
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2017-0522: first version (Yoann Ladroit).
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function init_java_fcn(main_figure)


min_size=get_init_fig_size(main_figure);


try
    javaFrame = get(main_figure,'JavaFrame');
    % Set minimum size of the figure
    jProx = javaFrame.fHG2Client.getWindow;
    
    jProx.setMinimumSize(java.awt.Dimension(min_size(3),min_size(4)));
    setappdata(main_figure,'javaWindow',jProx);

    
    % Create drag and drop for the figure object
    jObj = javaFrame.getFigurePanelContainer();
    dndcontrol.initJava();
    dndobj = dndcontrol(jObj);
    % Set Drop callback functions
    dndobj.DropFileFcn = @fileDropFcn;
    dndobj.DropStringFcn = '';
    setappdata(main_figure,'Dndobj',dndobj);
catch err
    print_errors_and_warnings(1,'error',err);
end


% nested function for above dndobj
    function fileDropFcn(~,evt)
        open_dropped_file(evt,main_figure);
    end
end