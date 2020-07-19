function listenEchoQuality(src,listdata,main_figure)
show_status_bar(main_figure,0);
main_menu=getappdata(main_figure,'main_menu');
layer=get_current_layer();

curr_disp=get_esp3_prop('curr_disp');
quality_str={'high' 'medium' 'low' 'very_low'};
rm_listeners(main_figure);

for it=1:numel(quality_str)
    set(main_menu.(sprintf('disp_%s_quality',quality_str{it})),'checked',strcmpi(listdata.AffectedObject.EchoQuality,quality_str{it}));
end


if ~isempty(layer)
    remove_interactions(main_figure);
    echo_tab_panel=getappdata(main_figure,'echo_tab_panel');
    axes_panel_comp=getappdata(main_figure,'Axes_panel');
    
    if ~isempty(axes_panel_comp)
        x=double(get(axes_panel_comp.echo_obj.main_ax,'xlim'));
        y=double(get(axes_panel_comp.echo_obj.main_ax,'ylim'));
        up_lim=1;
    else
        up_lim=0;
    end
    
    
    axes_panel=uitab(echo_tab_panel,'BackgroundColor',[1 1 1],'tag','axes_panel');
    load_axis_panel(main_figure,axes_panel);
    
    clean_echo_figures(main_figure,'Tag','mini_ax');
    undock_mini_axes_callback([],[],main_figure,'main_figure');
    
    load_secondary_freq_win(main_figure,0);
    init_sec_link_props(main_figure);
    
    update_display(main_figure,1,0);
    
    set(echo_tab_panel,'SelectedTab',axes_panel);
    
    if up_lim>0
        axes_panel_comp=getappdata(main_figure,'Axes_panel');
        set(axes_panel_comp.echo_obj.main_ax,'xlim',x);
        set(axes_panel_comp.echo_obj.main_ax,'ylim',y);
    end
    initialize_interactions_v2(main_figure);
end

init_listeners(getappdata(groot,'esp3_obj'));
curr_disp.CursorMode=curr_disp.CursorMode;
%listdata.AffectedObject.CursorMode='Normal';
hide_status_bar(main_figure);
end