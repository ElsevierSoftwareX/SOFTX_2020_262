function plot_ping_sv_spectrum_callback(~,~,main_figure)

layer=get_current_layer();
axes_panel_comp=getappdata(main_figure,'Axes_panel');
curr_disp=get_esp3_prop('curr_disp');
[trans_obj,idx_freq]=layer.get_trans(curr_disp);
trans=trans_obj;

ax_main=axes_panel_comp.main_axes;

x_lim=double(get(ax_main,'xlim'));

cp = ax_main.CurrentPoint;
x=cp(1,1);

x=nanmax(x,x_lim(1));
x=nanmin(x,x_lim(2));


xdata=trans.get_transceiver_pings();

[~,idx_ping]=nanmin(abs(xdata-x));
[~,idx_sort]=sort(layer.Frequencies);

cal_fm_cell=layer_obj.get_fm_cal([]);

for uui=idx_sort
    if strcmp(layer.Transceivers(uui).Mode,'FM')
        
        cal = cal_fm_cell{uui};
        
        range=layer.Transceivers(uui).get_transceiver_range();

        [~,Np]=layer.Transceivers(uui).get_pulse_length(idx_ping);
        [Sv_f,f_vec,r_disp]=layer.Transceivers(uui).processSv_f_r_2(layer.EnvData,idx_ping,range,Np,cal,[],'3D',0);

       [cmap,col_ax,col_lab,col_grid,~,~,~]=init_cmap(curr_disp.Cmap);
       df=abs(nanmean(diff(f_vec))/1e3);
        fig=new_echo_figure(main_figure,'Tag',sprintf('sv_ping %.0f%.0f kHz',df,layer.Frequencies(uui)/1e3),'Toolbar','esp3','MenuBar','esp3');
        ax=axes(fig);
        echo=image(ax,f_vec/1e3,r_disp,Sv_f,'CDataMapping','scaled');
        set(echo,'AlphaData',Sv_f>-80);
        xlabel('Frequency (kHz)');
        ylabel('Range(m)');
        caxis(curr_disp.getCaxField('sv')); colormap(cmap);
        title(sprintf('Sv(f) for %.0f kHz, Ping %i, Frequency resolution %.1fkHz',layer.Frequencies(uui)/1e3,idx_ping,df));
         
        colorbar(ax,'PickableParts','none');
        
        set(ax,'YColor',col_lab);
        set(ax,'XColor',col_lab);
        set(ax,'Color',col_ax,'GridColor',col_grid);

        clear Sp_f Compensation_f  f_vec
        
       
    else
        fprintf('%s not in  FM mode\n',layer.Transceivers(uui).Config.ChannelID);

    end
end