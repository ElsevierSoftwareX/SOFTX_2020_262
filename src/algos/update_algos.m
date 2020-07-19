%% update_algos.m
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
% * |main_figure|: TODO: write description and info on variable
%
% *OUTPUT VARIABLES*
%
% NA
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2017-03-28: header (Alex Schimel)
% * YYYY-MM-DD: first version (Yoann Ladroit)
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function update_algos(varargin)

p = inputParser;
addParameter(p,'algo_name',list_algos,@iscell);
addParameter(p,'idx_chan',[],@isnumeric);
parse(p,varargin{:});

layer = get_current_layer();
if isempty(layer)
    return;
end

main_figure=get_esp3_prop('main_figure');
curr_disp=get_esp3_prop('curr_disp');

if isempty(p.Results.idx_chan)
    [~,idx_chan] = layer.get_trans(curr_disp);
else
    idx_chan = p.Results.idx_chan;
end

algo_panels = getappdata(main_figure,'Algo_panels');

algo_panel=algo_panels.get_algo_panel(p.Results.algo_name);

for ui = 1:numel(algo_panel)
    layer.add_algo(algo_panel(ui).algo,'idx_chan',idx_chan);
end


end