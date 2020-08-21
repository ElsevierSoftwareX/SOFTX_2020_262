function plot_mean_aggregation_depth_callback(~,~,main_figure)

% get layer
layer = get_current_layer();
if isempty(layer)
    return;
end

% get curr_disp and color limits
curr_disp=get_esp3_prop('curr_disp');
if strcmp(curr_disp.Fieldname,'sv')
    cax = curr_disp.Cax;
else
    [cax,~,~] = init_cax('sv');
end

% get transceiver object and list of regions
trans_obj = layer.get_trans(curr_disp);
list_reg = trans_obj.regions_to_str();
if isempty(list_reg)
    return
end

% active region
active_reg = trans_obj.get_region_from_Unique_ID(curr_disp.Active_reg_ID);

% get mean depth per ping in region
for ireg=1:numel(active_reg)
    [mean_depth,Sa] = trans_obj.get_mean_depth_from_region(active_reg(ireg).Unique_ID);
    
    % get Sv, bottom, time and range within region
    idx_ping = active_reg(ireg).Idx_ping;
    idx_r     = active_reg(ireg).Idx_r;
    Sv    = trans_obj.Data.get_subdatamat('idx_r',idx_r,'idx_ping',idx_ping,'field','sv');
    range_all = trans_obj.get_transceiver_range();
    range_end = range_all(end);
    bot_r = trans_obj.get_bottom_range;
    bot_r(bot_r==0)     = range_end;
    bot_r(isnan(bot_r)) = range_end;
    bot_r = bot_r(idx_ping);
    time = trans_obj.Time(idx_ping);
    range = trans_obj.get_transceiver_range(idx_r);
    
    % get colormap
    cmap = init_cmap(curr_disp.Cmap);
    
    %% new figure
    fig = new_echo_figure(main_figure,'Toolbar','esp3','MenuBar','esp3','Tag',sprintf('mean_aggr%s',active_reg(ireg).Unique_ID),'Name',active_reg(ireg).print());
    
    % top axis
    ax1 = axes(fig,'units','normalized','outerposition',[0 0.5 1 0.5]);
    u = image(trans_obj.Time(idx_ping),range,Sv,'CDataMapping','scaled');
    hold(ax1,'on');
    grid(ax1,'on')
    plot(ax1,time,mean_depth,'r','linewidth',2);
    plot(ax1,time,bot_r)
    ylabel(ax1,'Depth (m)');
    datetick(ax1,'x')
    caxis(ax1,cax)
    colormap(ax1,cmap);
    set(u,'alphadata',Sv>=cax(1));
    
    % bottom axis
    ax2 = axes(fig,'units','normalized','outerposition',[0 0 1 0.5]);
    plot(ax2,time,Sa,'k','linewidth',2);
    datetick(ax2,'x')
    ylabel(ax2,'S_a (dB re 1 m^2/m^{-2})')
    xlabel(ax2,'Time')
    grid(ax2,'on');
    linkaxes([ax1 ax2],'x')
end

end