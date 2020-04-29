function init_sec_link_props(main_figure)
secondary_freq=getappdata(main_figure,'Secondary_freq');

if ~isempty(secondary_freq.axes)
    if isempty(secondary_freq.link_props_side_ax_internal)
       secondary_freq.link_props_top_ax_internal=linkprop([secondary_freq.axes secondary_freq.top_ax],{'XLim' 'XTick'});
       secondary_freq.link_props_side_ax_internal=linkprop([secondary_freq.axes secondary_freq.side_ax],{'YLim' 'YDir' 'Color' 'YColor'});
       setappdata(main_figure,'Secondary_freq',secondary_freq);
    end
end
