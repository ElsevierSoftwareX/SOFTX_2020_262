
function rm_Secondary_freq(src,~)
main_figure = get_esp3_prop('main_figure');

if ishghandle(main_figure)
    if isappdata(main_figure,'Secondary_freq')
        secondary_freq=getappdata(main_figure,'Secondary_freq');
        if isfield(secondary_freq,'link_props')
            delete(secondary_freq.echo_obj);
            delete(secondary_freq.link_props);
            delete(secondary_freq.link_props_top_ax);
            delete(secondary_freq.link_props_fig);
            delete(secondary_freq.link_props_top_ax_internal);
            delete(secondary_freq.link_props_side_ax_internal);
        end
        rmappdata(main_figure,'Secondary_freq');
    end
    delete(src);
    setappdata(main_figure,'Secondary_freq',init_secondary_axes_struct());
    
    curr_disp=get_esp3_prop('curr_disp');
    curr_disp.DispSecFreqs=0;
else
    delete(src);
end


end