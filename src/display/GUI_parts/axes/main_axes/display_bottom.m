
function display_bottom(main_figure,varargin)

layer=get_current_layer();

curr_disp=get_esp3_prop('curr_disp');
[trans_obj,~]=layer.get_trans(curr_disp);


info_panel_comp=getappdata(main_figure,'Info_panel');
set(info_panel_comp.percent_BP,'string',trans_obj.bp_percent2str());

[~,~,~,~,col_bot,~,~]=init_cmap(curr_disp.Cmap);


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

[echo_im_tot,main_axes_tot,~,trans_obj_tot,text_size,cids]=get_axis_from_cids(main_figure,main_or_mini);


for iax=1:length(main_axes_tot)
    trans_obj=trans_obj_tot{iax};
    
    idx_pings_lim=get(echo_im_tot(iax),'XData');
    idx_pings=nanmax(floor(idx_pings_lim(1)),1):ceil(idx_pings_lim(end));
    
    if ~isempty(trans_obj.Bottom.Sample_idx)
        idx_bottom=trans_obj.Bottom.Sample_idx(idx_pings);
        xdata=trans_obj.get_transceiver_pings(idx_pings);
        ydata=trans_obj.get_transceiver_samples();
    else
        idx_bottom=[];
        xdata=[];
        ydata=[];
    end
    bt_h=findobj(main_axes_tot(iax),{'tag','bottom'});
    if~isempty(idx_bottom)&&~isempty(xdata)&&~isempty(ydata)
        x=linspace(xdata(1),xdata(end),length(xdata));
        
        
        if ~strcmpi(main_axes_tot(iax).UserData.geometry_y,'depth')            
            di=-1/2;           
            ydata=trans_obj.get_transceiver_samples()+di;
            y=nan(size(x));
            y(~isnan(idx_bottom))=ydata(idx_bottom(~isnan(idx_bottom)));
            y((y-di)==numel(ydata))=nan;
        else
            if curr_disp.DispSecFreqsWithOffset>0
                y=trans_obj.get_bottom_depth(idx_pings);
            else
                y=trans_obj.get_bottom_range(idx_pings);
            end
            
        end
        
        
        set(bt_h,'XData',x,'YData',y,'visible',curr_disp.DispBottom);
        
    else
        set(bt_h,'XData',nan,'YData',nan,'visible',curr_disp.DispBottom);
    end
    
end

end






