function init_link_prop(main_figure)

linked_prop=getappdata(main_figure,'LinkedProps');

if ~isempty(linked_prop)
    fields=fieldnames(linked_prop);
    for i=1:numel(linked_prop)
        delete(linked_prop.(fields{i}));
    end
end

secondary_freq=getappdata(main_figure,'Secondary_freq');
mini_axes_comp=getappdata(main_figure,'Mini_axes');
echo_int_tab_comp=getappdata(main_figure,'EchoInt_tab');
axes_panel_comp=getappdata(main_figure,'Axes_panel');

echo_int_fig=ancestor(echo_int_tab_comp.main_ax,'figure');
mini_ax_fig=ancestor(mini_axes_comp.mini_ax,'figure');

linked_prop.alpha_map=linkprop([main_figure mini_ax_fig secondary_freq.fig echo_int_fig],{'AlphaMap'});

linked_prop.general=linkprop([axes_panel_comp.main_axes mini_axes_comp.mini_ax...
    axes_panel_comp.haxes axes_panel_comp.vaxes ...
    echo_int_tab_comp.main_ax  echo_int_tab_comp.h_ax echo_int_tab_comp.v_ax ...
    secondary_freq.axes secondary_freq.side_ax secondary_freq.top_ax],...
    {'YColor','XColor','GridLineStyle','Color','GridColor','MinorGridColor'});

linked_prop.general_clim=linkprop([axes_panel_comp.main_axes mini_axes_comp.mini_ax...
    axes_panel_comp.haxes axes_panel_comp.vaxes ...
    secondary_freq.axes secondary_freq.side_ax secondary_freq.top_ax],...
    {'CLim'});

linked_prop.ydir=linkprop([axes_panel_comp.main_axes axes_panel_comp.vaxes echo_int_tab_comp.main_ax secondary_freq.axes mini_axes_comp.mini_ax...
      echo_int_tab_comp.main_ax echo_int_tab_comp.v_ax],...
    {'YDir'});

% linked_prop.xlim=linkprop([axes_panel_comp.main_axes axes_panel_comp.haxes],{'XLim'});
% linked_prop.ylim=linkprop([axes_panel_comp.main_axes axes_panel_comp.vaxes],{'YLim'});

linked_prop.xtick=linkprop([axes_panel_comp.main_axes axes_panel_comp.haxes secondary_freq.top_ax],{'XTick'});
linked_prop.ytick=linkprop([axes_panel_comp.main_axes axes_panel_comp.vaxes],{'YTick'});

linked_prop.xticklabel=linkprop([axes_panel_comp.haxes secondary_freq.top_ax],{'XTickLabel'});
linked_prop.yticklabel=linkprop([axes_panel_comp.vaxes secondary_freq.top_ax],{'YTickLabel'});

% linked_prop.ylim=linkprop([axes_panel_comp.main_axes],{'YLim'});
% linked_prop.xlim=linkprop([axes_panel_comp.main_axes],{'XLim'});

setappdata(main_figure,'LinkedProps',linked_prop);



