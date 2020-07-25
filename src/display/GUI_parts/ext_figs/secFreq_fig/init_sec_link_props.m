function init_sec_link_props(main_figure)
secondary_freq=getappdata(main_figure,'Secondary_freq');

if ~isempty(secondary_freq.echo_obj)
    if isempty(secondary_freq.link_props_side_ax_internal)
       secondary_freq.link_props_top_ax_internal=linkprop([secondary_freq.echo_obj.get_main_ax() secondary_freq.echo_obj.get_hori_ax()],{'XLim' 'XTick'});
       secondary_freq.link_props_side_ax_internal=linkprop([secondary_freq.echo_obj.get_main_ax() secondary_freq.echo_obj.get_vert_ax()],{'YTick' 'YLim' 'YDir' 'Color' 'YColor'});
       setappdata(main_figure,'Secondary_freq',secondary_freq);
    end
end
