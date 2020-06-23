function display_ping_impedance_cback(src,~,main_figure,idx_ping,new)
hfigs=getappdata(main_figure,'ExternalFigures');
if ~isempty(hfigs)
    hfigs(~isvalid(hfigs))=[];
end
idx_fig=[];
if ~isempty(hfigs)
    idx_fig=find(strcmp({hfigs(:).Tag},'Impedance'));
end
if isempty(idx_fig)&&new==0
    return;
end

layer=get_current_layer();
axes_panel_comp=getappdata(main_figure,'Axes_panel');
curr_disp=get_esp3_prop('curr_disp');
[trans_obj,idx_freq]=layer.get_trans(curr_disp);

linestyles={'-' '--' ':' '-.'};
ax_main=axes_panel_comp.echo_obj.main_ax;

if isempty(idx_ping)
    x_lim=double(get(ax_main,'xlim'));
    
    
    cp = ax_main.CurrentPoint;
    x=cp(1,1);
    %y=cp(1,2);
    
    x=nanmax(x,x_lim(1));
    x=nanmin(x,x_lim(2));
    xdata=trans_obj.get_transceiver_pings();
    [~,idx_ping]=nanmin(abs(xdata-x));
end
[Z,f_vec]=trans_obj.compute_ping_impedance(idx_ping);

if any(~cellfun(@isempty,Z))
    n_fig=sprintf('Channel %s Impedance for ping %i',layer.ChannelID{idx_freq},idx_ping);
     
    if ~isempty(idx_fig)
        h_fig=hfigs(idx_fig);
        ax= findobj(h_fig,'Type','axes');
        lines= findobj(ax,'Type','line');
        delete(lines);
        h_fig.Name=n_fig;
    elseif new>0
        h_fig=new_echo_figure(main_figure,'Name',n_fig,'Tag','Impedance');
        ax= axes(h_fig,'nextplot','add','OuterPosition',[0 0 1 1]);
    else
        return;
    end
    
    
    yyaxis(ax,'left');
    ax.YAxis(1).Color = 'r';
    ylabel(ax,'abs(Z) (\Omega)');
    
    yyaxis(ax,'right');
    ylabel(ax,'angle(Z)');
    
    ax.YAxis(2).Color = 'k';
    ax.YAxis(2).TickLabelFormat  = '%g^\\circ';
    
    % legend(ax,'boxoff')
    ylabel(ax,'angle(Z)');
    grid(ax,'on');
    box(ax,'on');
    
    x_vals=[];
    for i=1:numel(Z)
        if isempty(Z{i})
            continue;
        end
        switch trans_obj.Mode
            case 'FM'
                x_vals=f_vec{i}/1e3;
                x_label='kHz';
            otherwise
                x_vals=f_vec{i};
                x_label='sample number';
        end
        ix=rem(i,numel(Z));
        ix(ix==0)=numel(Z);
        yyaxis(ax,'left');
        plot(ax,x_vals,abs(Z{i}),'r','linestyle',linestyles{ix},'Marker','none');
        yyaxis(ax,'right');
        plot(ax,x_vals,(angle(Z{i})/pi*180),'k','linestyle',linestyles{ix},'Marker','none');
    end
    
    xlabel(ax,x_label);
    if(~isempty(x_vals))
        xlim(ax,[nanmin(x_vals) nanmax(x_vals)]);
    end
    
else
    if ~isempty(src)
        warndlg_perso(main_figure,'',sprintf('No impedance measuremanent for channel %s',trans_obj.Config.ChannelID));
    end
end