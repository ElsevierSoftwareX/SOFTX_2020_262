function clear_echo_regions(echo_obj,ids)

for iax=1:length(echo_obj)
    if isempty(ids)
        delete(findobj(ancestor(echo_obj.get_main_ax(iax),'figure'),'Type','UiContextMenu','-and','Tag','RegionContextMenu'));
        delete(findobj(echo_obj.get_main_ax(iax),'tag','region','-or','tag','region_text'));
    else
        for i=1:numel(ids)
            delete(findobj(echo_obj.get_main_ax(iax),{'tag','region','-or','tag','region_text'},'-and','UserData',ids{i}));
            delete(findobj(ancestor(echo_obj.get_main_ax(iax),'figure'),'Type','UiContextMenu','-and','Tag','RegionContextMenu','-and','UserData',ids{i}));
        end
    end

end