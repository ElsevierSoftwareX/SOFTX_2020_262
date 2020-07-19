function display_regions(varargin)

% profile on;

layer=get_current_layer();

curr_disp=get_esp3_prop('curr_disp');
main_figure=get_esp3_prop('main_figure');

axes_panel_comp=getappdata(main_figure,'Axes_panel');

if ~isempty(varargin)
    if ischar(varargin{1})
        switch varargin{1}
            case 'both'
                main_or_mini={'main' 'mini' curr_disp.ChannelID};
            case 'mini'
                main_or_mini={'mini'};
            case 'main'
                main_or_mini={'main' curr_disp.ChannelID};
            case 'all'
                main_or_mini=union({'main' 'mini'},layer.ChannelID);
        end
    elseif iscell(varargin{1})
        main_or_mini=varargin{1};
    end
else
    main_or_mini=union({'main' 'mini'},layer.ChannelID);
end

[echo_obj,trans_obj_tot,text_size,~]=get_axis_from_cids(main_figure,main_or_mini);

for iax=1:length(echo_obj)
    trans_obj=trans_obj_tot(iax);
    main_axes=echo_obj.get_main_ax(iax);
    
    reg_plot = echo_obj(iax).display_echo_regions(trans_obj,'curr_disp',curr_disp,'text_size',text_size(iax));
    
    if main_axes==axes_panel_comp.echo_obj.main_ax
            
        for ii=1:length(reg_plot)
            reg_curr = trans_obj.get_region_from_Unique_ID(reg_plot(ii).UserData);
            iptaddcallback(reg_plot(ii),'ButtonDownFcn',{@set_active_reg,reg_curr.Unique_ID,main_figure});
            iptaddcallback(reg_plot(ii),'ButtonDownFcn',{@move_reg_callback,reg_curr.Unique_ID,main_figure});
            
            create_region_context_menu(reg_plot(ii),main_figure,reg_curr.Unique_ID);
            ipt.enterFcn =  @(figHandle, currentPoint)...
                set(figHandle, 'Pointer', 'hand');
            ipt.exitFcn =  [];
            ipt.traverseFcn = [];
            iptSetPointerBehavior(reg_plot(ii),ipt);
            
        end
    end
    
end

end



