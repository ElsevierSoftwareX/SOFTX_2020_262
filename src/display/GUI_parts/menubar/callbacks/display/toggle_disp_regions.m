function toggle_disp_regions(main_figure)

curr_disp=get_esp3_prop('curr_disp');
layer=get_current_layer();

if isempty(layer)
    return;
end

[echo_obj,~,~,~]=get_axis_from_cids(main_figure,union({'main' 'mini'},layer.ChannelID));
for iax=1:length(echo_obj)
    main_axes=echo_obj.get_main_ax(iax);

    u_reg_image=findobj(main_axes,'tag','region','-and',{'Type','Image','-or','Type','Patch'});
    set(u_reg_image,'visible',curr_disp.DispReg);
   
    u_reg_polygon=findobj(main_axes,'tag','region','-and','Type','Polygon');
    switch curr_disp.DispReg
        case 'off'
            set(u_reg_polygon,'FaceAlpha',0);
        case 'on'
            set(u_reg_polygon,'FaceAlpha',0.4);
    end
end
