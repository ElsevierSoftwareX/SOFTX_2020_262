function update_info_panel(~,~,force_update)
%profile on;
global DEBUG
if isempty(DEBUG)
    DEBUG =0;
end
esp3_obj=getappdata(groot,'esp3_obj');

%dpause=1e-2;
%pause(dpause);
if isempty(esp3_obj)
    %pause(dpause);
    return;
end

main_figure=esp3_obj.main_figure;

if isempty(main_figure)||~ishandle(main_figure)
    %pause(dpause);
    return;
end

if ~isdeployed()&&DEBUG
    disp('Update info panel');
    disp(datestr(now,'HH:MM:SS.FFF'));
end

try
    layer=get_current_layer();
    
    echo_tab_panel=getappdata(main_figure,'echo_tab_panel');
    info_panel_comp=getappdata(main_figure,'Info_panel');
    axes_panel_comp=getappdata(main_figure,'Axes_panel');
    
    bool =isempty(axes_panel_comp)||(~isa(axes_panel_comp.axes_panel,'matlab.ui.Figure') && ~strcmpi(echo_tab_panel.SelectedTab.Tag,'axes_panel'));
    if  bool ||isempty(layer)||~isvalid(layer)
        %pause(dpause);
        return;
    end
    
    curr_disp=get_esp3_prop('curr_disp');    
    cur_str=sprintf('Cursor mode: %s',curr_disp.CursorMode);
    set(info_panel_comp.cursor_mode,'String',cur_str);
    
    [trans_obj,~]=layer.get_trans(curr_disp);
    
    if isempty(trans_obj)
        %pause(dpause);
        return;
    end
    
    Range_trans=trans_obj.get_transceiver_range();
    Bottom=trans_obj.Bottom;
    Time_trans=trans_obj.Time;
    Number=trans_obj.get_transceiver_pings();
    Samples=trans_obj.get_transceiver_samples();
    
    
    Depth_corr=trans_obj.get_transducer_depth();
    
    Lat=trans_obj.GPSDataPing.Lat;
    Long=trans_obj.GPSDataPing.Long;
    
    
    ax_main=axes_panel_comp.echo_obj.main_ax;
    
    cp = ax_main.CurrentPoint;
    
    if force_update&&any(cp(1:2)<0)
        cp=[1 1];
    elseif any(cp(1:2)<0)
        %pause(dpause);
        return;
    end
    
    %disp('up');
    x_lim=double(get(ax_main,'xlim'));
    y_lim=double(get(ax_main,'ylim'));
    
    set(axes_panel_comp.echo_obj.hori_ax,'xlim',x_lim);
    set(axes_panel_comp.echo_obj.vert_ax,'ylim',y_lim);
    
    
    cdata=single(get(axes_panel_comp.echo_obj.echo_surf,'CData'));
    
    xdata=double(get(axes_panel_comp.echo_obj.echo_surf,'XData'));
    ydata=double(get(axes_panel_comp.echo_obj.echo_surf,'YData'));
    
    idx_x_keep=xdata>=x_lim(1)&xdata<=x_lim(2);
    idx_y_keep=ydata>=y_lim(1)&ydata<=y_lim(2);
    
    cdata=cdata(idx_y_keep,idx_x_keep);
    
    [nb_samples_red,nb_pings_red]=size(cdata);
    
    
    
    nb_pings=length(Time_trans);
    nb_samples=length(Range_trans);
    
    
    xdata_red=linspace(x_lim(1),x_lim(2),nb_pings_red);
    
    dxi=+1/2;
    
    xdata_red=xdata_red+dxi;
    ydata_red=linspace(y_lim(1),y_lim(2),nb_samples_red);
    idx_ping=ceil(xdata(idx_x_keep));
    idx_rs=ceil(ydata(idx_y_keep));
    
    %idx_ping=ceil(xdata);
    %idx_rs=ceil(ydata);
    
    
    x=round(cp(1,1));
    y=round(cp(1,2));
    
    if (x>x_lim(2)||x<x_lim(1)|| y>y_lim(2)||y<y_lim(1))&&force_update==0
        %pause(dpause);
        return;
    end
    
    cax=curr_disp.Cax;
    
    x=nanmax(x,x_lim(1));
    x=nanmin(x,x_lim(2));
    
    y=ceil(nanmax(y,y_lim(1)));
    y=ceil(nanmin(y,y_lim(2)));
    
    if ~isempty(cdata)
        %         [~,idx_ping]=nanmin(abs(xdata-x));
        %         idx_ping=idx_ping+idx_ping_ori-1;
        idx_ping=ceil(x);
        idx_ping=nanmin(nb_pings,idx_ping);
        idx_ping=nanmax(1,idx_ping);
        %         [~,idx_r]=nanmin(abs(ydata-y));
        
        idx_r=y;
        idx_r=nanmin(nb_samples,idx_r);
        if nb_pings_red<nb_pings
            [~,idx_ping_red]=nanmin(abs(xdata_red-x));
        else
            idx_ping_red=idx_ping;
        end
        
        if nb_samples_red<nb_samples
            [~,idx_r_red]=nanmin(abs(ydata_red-y));
        else
            idx_r_red=idx_r;
        end
        
        
        if idx_ping<=length(Bottom.Sample_idx)
            if ~isnan(Bottom.Sample_idx(idx_ping))
                bot_val=Bottom.Sample_idx(idx_ping);
            else
                bot_val=nan;
            end
        else
            bot_val=nan;
        end
        bot_x_val=cax(:)'+[-3 3];
        bot_y_val=cax(:)'+[-3 3];
        
        if idx_r==0||idx_ping==0
            %pause(dpause);
            return;
        end
        
        switch curr_disp.CursorMode
            case {'Edit Bottom' 'Bad Pings'}
                switch curr_disp.Fieldname
                    case {'sv','sp','sp_comp','spdenoised','svdenoised','spunmatched','svunmatched','powerunmatched','powerdenoised','power'}
                        sub_bot=Bottom.Sample_idx(idx_ping);
                        sub_tag=Bottom.Tag(idx_ping);
                        sub_bot(sub_tag==0)=inf;
                        sub_bot=sub_bot-idx_rs(1)+1;
                        bot_sample_red=downsample(round(sub_bot*nb_samples_red/(idx_rs(end)-idx_rs(1)+1)),round(length(idx_ping)/nb_pings_red));
                        
                        idx_r_tot=(1:nb_samples_red)';
                        idx_r_bot=idx_r_tot(idx_r_tot>=nanmin(bot_sample_red-3)&idx_r_tot<=nanmax(bot_sample_red));
                        
                        
                        idx_keep=idx_r_bot<bot_sample_red&...
                            idx_r_bot>=(bot_sample_red-3);
                        
                        idx_keep(:,bot_sample_red>=nb_samples)=0;
                        cdata_bot=cdata(idx_r_bot,:);
                        cdata_bot(~idx_keep)=nan;
                        horz_val=nanmax(cdata_bot,[],1);
                        
                        if isempty(horz_val)
                            horz_val=nan(1,numel(bot_sample_red));
                        end
                        idx_low=~((horz_val>=prctile(cdata_bot(idx_keep),90))&(horz_val>=(curr_disp.Cax(2)-6)))|bot_sample_red==nb_samples_red;
                        
                        bot_x_val=[cax(1)-3  cax(2)+3];
                        
                        bot_y_val=[cax(1)-3 nanmax(cax(2),nanmax(horz_val))+10];
                        
                        horz_val(horz_val<cax(1))=cax(1);
                    otherwise
                        horz_val=cdata(idx_r_red,:);
                        horz_val(horz_val>cax(2))=cax(2);
                        horz_val(horz_val<cax(1))=cax(1);
                        idx_low=ones(size(horz_val));
                        %idx_high=zeros(size(horz_val));
                end
                
            otherwise
                horz_val=cdata(idx_r_red,:);
                horz_val(horz_val>cax(2))=cax(2);
                horz_val(horz_val<cax(1))=cax(1);
                idx_low=ones(size(horz_val));
                %idx_high=zeros(size(horz_val));
                
        end
        
        
        vert_val=cdata(:,idx_ping_red);
        vert_val(vert_val<=-999)=nan;
        
        vert_val(vert_val>cax(2))=cax(2);
        vert_val(vert_val<cax(1))=cax(1);
        
        
        t_n=Time_trans(idx_ping);
        
        i_str='';
        
        if length(layer.SurveyData)>=1
            for is=1:length(layer.SurveyData)
                surv_temp=layer.get_survey_data('Idx',is);
                if ~isempty(surv_temp)
                    if t_n>=surv_temp.StartTime&&t_n<=surv_temp.EndTime
                        i_str=surv_temp.print_survey_data();
                    end
                end
            end
        end
        
        
        if Depth_corr(idx_ping)~=0
            xy_string=sprintf('Range: %.2fm Range Corr: %.2fm\n  Sample: %.0f Ping #:%.0f of  %.0f',Range_trans(idx_r),Range_trans(idx_r)+Depth_corr(idx_ping),Samples(idx_r),Number(idx_ping),Number(end));
        else
            xy_string=sprintf('Range: %.2fm\n  Sample: %.0f Ping #%.0f of  %.0f',Range_trans(idx_r),Samples(idx_r),Number(idx_ping),Number(end));
        end
        
        if ~isempty(Lat)&&nansum(Lat+Long)>0
            [lat_str,lon_str]=print_pos_str(Lat(idx_ping),Long(idx_ping));
            pos_string=sprintf('%s\n%s',lat_str,lon_str);
            pos_weigtht='normal';
            if ~isdeployed()&&DEBUG
                disp('Update info panel: lat/lon');
                disp(datestr(now,'HH:MM:SS.FFF'));
            end
        else
            pos_string=sprintf('No Navigation Data');
            pos_weigtht='Bold';
            
        end
        time_str=datestr(Time_trans(idx_ping),'yyyy-mm-dd HH:MM:SS');
        
        switch lower(deblank(curr_disp.Fieldname))
            case{'alongangle','acrossangle'}
                val_str=sprintf('Angle: %.2f%c',cdata(idx_r_red,idx_ping_red),char(hex2dec('00BA')));
            case{'alongphi','acrossphi'}
                val_str=sprintf('Phase: %.2f%c',cdata(idx_r_red,idx_ping_red),char(hex2dec('00BA')));
            case {'fishdensity'}
                val_str=sprintf('%s: %.2g fish/m^3',curr_disp.Type,cdata(idx_r_red,idx_ping_red));
            otherwise
                val_str=sprintf('%s: %.2f dB',curr_disp.Type,cdata(idx_r_red,idx_ping_red));
        end
        
        iFile=trans_obj.Data.FileId(idx_ping);
        [~,file_curr,~]=fileparts(layer.Filename{iFile});
        
        summary_str=sprintf('%s. Mode: %s Freq: %.0f kHz Power: %.0fW Pulse: %.3fms',file_curr,trans_obj.Mode,curr_disp.Freq/1000,...
            trans_obj.get_params_value('TransmitPower',idx_ping),...
            trans_obj.get_params_value('PulseLength',idx_ping)*1e3);
        
        
        set(info_panel_comp.i_str,'String',i_str);
        set(info_panel_comp.summary,'string',summary_str);
        set(info_panel_comp.xy_disp,'string',xy_string);
        set(info_panel_comp.pos_disp,'string',pos_string,'Fontweight',pos_weigtht);
        set(info_panel_comp.time_disp,'string',time_str);
        set(info_panel_comp.value,'string',val_str);
        
        axh=axes_panel_comp.echo_obj.hori_ax;
        axh_plot_high=axes_panel_comp.h_axes_plot_high;
        axh_plot_low=axes_panel_comp.h_axes_plot_low;
        
        axv=axes_panel_comp.echo_obj.vert_ax;
        axv_plot=axes_panel_comp.v_axes_plot;
        axv_bot=axes_panel_comp.v_bot_val;
        axv_curr=axes_panel_comp.v_curr_val;
        
        set(axv_plot,'XData',vert_val,'YData',ydata_red);
        
        if bot_x_val(2)>bot_x_val(1)
            set(axv,'xlim',bot_x_val);
        end
        
        if bot_y_val(2)>bot_y_val(1)
            set(axh,'ylim',bot_y_val);
        end
        
        depth=trans_obj.get_bottom_range(idx_ping);
        if ~isnan(depth)
            str=sprintf('%.2fm',depth);
        else
            str='';
        end
        
        set(axv_curr,'value',idx_r,'Label',sprintf('%.2fm',Range_trans(idx_r)));

        
        if ~isnan(bot_val)
            set(axv_bot,'value',bot_val,'Label',str);
        end
        
        horz_val_high=horz_val;
        horz_val_high(idx_low>0)=nan;
        
        set(axh_plot_low,'XData',xdata_red,'YData',horz_val);
        set(axh_plot_high,'XData',xdata_red,'YData',horz_val_high);
        
        set(axes_panel_comp.h_curr_val,'Value',xdata_red(idx_ping_red));
        
        display_ping_impedance_cback([],[],main_figure,idx_ping,0);
        
        update_boat_position(main_figure,idx_ping,0);
        
    end
    
catch err
    if ~isdeployed
        print_errors_and_warnings(1,'error',err)
        disp('Could not update info panel');
    end
end

end