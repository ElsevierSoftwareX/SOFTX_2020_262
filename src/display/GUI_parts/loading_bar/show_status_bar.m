function [load_bar_comp,state_axis]=show_status_bar(main_figure,varargin)
load_bar_comp=[];
state_axis=false;

if isempty(main_figure)
    return;
end
load_bar_comp=getappdata(main_figure,'Loading_bar');
state_axis=false;

if ~isempty(load_bar_comp)
    state_axis=strcmpi(load_bar_comp.progress_bar.progaxes.Visible,'on');
 
    if nargin>1
        if varargin{1}>0
            load_bar_comp.progress_bar.setVisible(varargin{1});
        end
    else
        load_bar_comp.progress_bar.setVisible(1);
    end
    drawnow;
end