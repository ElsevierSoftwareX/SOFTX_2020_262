function listenDispSecFreqs(src,~,main_figure)

curr_disp=get_esp3_prop('curr_disp');
layer=get_current_layer();

if isempty(layer)
    return;
end

switch curr_disp.DispSecFreqs
    case 1
        switch src.Name
            case 'DispSecFreqsOr'
                load_secondary_freq_win(main_figure,1);
            otherwise
                load_secondary_freq_win(main_figure,0);
        end
        init_sec_link_props(main_figure);
        update_axis(main_figure,1,'main_or_mini',layer.ChannelID);
        update_cmap(main_figure);
        set_alpha_map(main_figure,'main_or_mini',layer.ChannelID);
        display_regions(main_figure,union({'main' 'mini'},layer.ChannelID));
        display_bottom(main_figure);
        
        init_link_prop(main_figure);
        update_grid(main_figure);
    case 0
        if isappdata(main_figure,'Secondary_freq')
            secondary_freq=getappdata(main_figure,'Secondary_freq');
            
            delete(secondary_freq.link_props_top_ax_internal);
            delete(secondary_freq.link_props_side_ax_internal);
            delete(secondary_freq.fig);
            
            secondary_freq_init=init_secondary_axes_struct();
          
            setappdata(main_figure,'Secondary_freq',secondary_freq_init);
        else
           setappdata(main_figure,'Secondary_freq',secondary_freq_init); 
        end
end

display_tab_comp=getappdata(main_figure,'Display_tab');

if ~isempty(display_tab_comp)
    display_tab_comp.sec_freq_disp.Value=curr_disp.DispSecFreqs;
end


end