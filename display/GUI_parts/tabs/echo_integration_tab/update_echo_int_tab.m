function update_echo_int_tab(main_figure,new)

if ~isappdata(main_figure,'EchoInt_tab')
    echo_tab_panel=getappdata(main_figure,'echo_tab_panel');
    load_echo_int_tab(main_figure,echo_tab_panel);
    return;
end

echo_int_tab_comp=getappdata(main_figure,'EchoInt_tab');
layer_obj=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');

survey_options_obj=layer_obj.get_survey_options();

if isempty(survey_options_obj)
    survey_options_obj=survey_options_cl();
end
freqs=layer_obj.Frequencies;

if new>0
    [~,idx_freq]=layer_obj.get_trans(curr_disp); 
else
    idx_freq = echo_int_tab_comp.tog_tfreq.Value;
end

if isempty(layer_obj.GPSData.Lat)
    units_w= {'pings','seconds'};
    xaxis_opt={'Ping Number' 'Time'};
else
    units_w= {'meters','pings','seconds'};
    xaxis_opt={'Distance' 'Ping Number' 'Time' 'Lat' 'Long'};
end

set(echo_int_tab_comp.cell_w_unit,'String',units_w);

idx_w=find(strcmpi(echo_int_tab_comp.cell_w_unit.String,survey_options_obj.Vertical_slice_units));

if isempty(idx_w)
    idx_w=1;
end

if ~isempty(echo_int_tab_comp.cell_w_unit.Value)
    echo_int_tab_comp.cell_w_unit.Value=idx_w;
end

echo_int_tab_comp.cell_w.String=num2str(survey_options_obj.Vertical_slice_size);
echo_int_tab_comp.cell_h.String=num2str(survey_options_obj.Horizontal_slice_size);

echo_int_tab_comp.denoised.Value=survey_options_obj.Denoised>0;
echo_int_tab_comp.sv_thr_bool.Value=survey_options_obj.SvThr>-999;
echo_int_tab_comp.sv_thr.String=num2str(survey_options_obj.SvThr);

echo_int_tab_comp.shadow_zone.Value=survey_options_obj.Shadow_zone>0;
echo_int_tab_comp.shadow_zone_h.String=num2str(survey_options_obj.Shadow_zone_height);

echo_int_tab_comp.d_min.String=num2str(survey_options_obj.DepthMin);
echo_int_tab_comp.d_max.String=num2str(survey_options_obj.DepthMax);

echo_int_tab_comp.motion_correction.Value=survey_options_obj.Motion_correction>0;

set(echo_int_tab_comp.tog_xaxis,'String',xaxis_opt);

if echo_int_tab_comp.tog_xaxis.Value>numel(xaxis_opt)
    echo_int_tab_comp.tog_xaxis.Value=1;
end

if new>0    
    set(echo_int_tab_comp.tog_freq,'String',num2str(freqs'/1e3,'%.0f kHz'),'Value',idx_freq);    
    reset_plot(echo_int_tab_comp);
end

if ~isempty(layer_obj.EchoIntStruct.idx_freq_out)
    freqs_out=layer_obj.Frequencies(nanmin(layer_obj.EchoIntStruct.idx_freq_out,numel(layer_obj.Frequencies)));
    idx_main=find(layer_obj.Frequencies(idx_freq)==freqs_out);
    if isempty(idx_main)
        idx_main=1;
    end
    set(echo_int_tab_comp.tog_tfreq,'String',num2str(freqs_out'/1e3,'%.0f kHz'),'Value',idx_main);
else
    set(echo_int_tab_comp.tog_tfreq,'String','--','Value',1); 
    idx_main=[];
end


if isempty(layer_obj.EchoIntStruct.idx_freq_out)
    setappdata(main_figure,'EchoInt_tab',echo_int_tab_comp);
    return;
end


if ~isempty(idx_main)&&~isempty(layer_obj.EchoIntStruct.output_2D{idx_main})
    echo_int_tab_comp.tog_ref.String =layer_obj.EchoIntStruct.output_2D_type{idx_main};
    
    idx_ref=1;
    
    echo_int_tab_comp.tog_ref.Value=idx_ref;
    ref=layer_obj.EchoIntStruct.output_2D_type{idx_main}{idx_ref};
    
    
    out=layer_obj.EchoIntStruct.output_2D{idx_main}{idx_ref};
    
    s_eint=gather(size(out.eint));
    
    if any(s_eint==1)
        return;
    end
    %{'Ping Number' 'Distance' 'Time' 'Lat' 'Long'}
    x_disp_t=echo_int_tab_comp.tog_xaxis.String{echo_int_tab_comp.tog_xaxis.Value};
    switch x_disp_t
        case 'Ping Number'
            x_disp=out.Ping_S;
        case 'Distance'
            x_disp=out.Dist_S;
        case  'Time'
            x_disp=out.Time_S;
        case 'Lat'
            x_disp=out.Lat_S;
        case 'Long'
            x_disp=out.Lon_S;
    end
    if  ~any(~isnan(x_disp))
        x_disp=out.Ping_S;
        x_disp_t='Ping Number';
    end
    
    x_ticks=unique(nanmean(x_disp,1));
    nb_x=numel(x_ticks);
    dx=ceil(nb_x/40);
    
    if dx>1
        x_ticks=x_ticks(1:dx:end);
    end
    
    if (strcmpi(x_disp_t,'Distance')&&strcmpi(layer_obj.EchoIntStruct.survey_options.Vertical_slice_units,'meters'))||...
            (strcmpi(x_disp_t,'Ping Number')&&strcmpi(layer_obj.EchoIntStruct.survey_options.Vertical_slice_units,'pings'))...
            ||(strcmpi(x_disp_t,'Time')&&strcmpi(layer_obj.EchoIntStruct.survey_options.Vertical_slice_units,'seconds'))
        xl=num2cell(floor(x_ticks/layer_obj.EchoIntStruct.survey_options.Vertical_slice_size)*layer_obj.EchoIntStruct.survey_options.Vertical_slice_size);
    else
        xl=num2cell(x_ticks);
    end
    
    switch x_disp_t
        case 'Ping Number'
            x_labels=cellfun(@(x) sprintf('%d',x),xl,'UniformOutput',0);
        case 'Distance'
            x_labels=cellfun(@(x) sprintf('%.0fm',x),xl,'UniformOutput',0);
        case  'Time'
            h_fmt='HH:MM:SS';
            x_labels=cellfun(@(x) datestr(x,h_fmt),xl,'UniformOutput',0);
        case 'Lat'
            [x_labels,~]=cellfun(@(x) print_pos_str(x,zeros(size(x))),xl,'UniformOutput',0);
        case 'Long'
            [~,x_labels]=cellfun(@(x) print_pos_str(zeros(size(x)),x),xl,'UniformOutput',0);
    end
    
    
    switch lower(ref)
        case 'surface'
            y_disp=out.Depth_min;
        case {'bottom' 'transducer'}
            y_disp=out.Range_ref_min;
    end
    
    
    y_disp = gather(y_disp);
    
    y_disp_tmp=y_disp;
    y_disp_tmp(isnan(y_disp_tmp)|isinf(y_disp_tmp))=[];
    y_ticks=linspace(nanmin(y_disp_tmp(:)),nanmax(y_disp_tmp(:)),size(y_disp,1));
    
    nb_y=numel(y_ticks);
    dy=ceil(nb_y/20);
    
    if dy>1
        y_ticks=y_ticks(1:dy:end);
    end
    
    if layer_obj.EchoIntStruct.survey_options.Horizontal_slice_size>1
        yl=num2cell(floor(abs(y_ticks)/layer_obj.EchoIntStruct.survey_options.Horizontal_slice_size)*layer_obj.EchoIntStruct.survey_options.Horizontal_slice_size);
        y_labels=cellfun(@(x) sprintf('%.0fm',x),yl,'UniformOutput',0);
    else
        yl=num2cell(abs(y_ticks));
        y_labels=cellfun(@(x) sprintf('%.0fm',x),yl,'UniformOutput',0);
    end
    legend_str={};
    switch echo_int_tab_comp.tog_type.String{echo_int_tab_comp.tog_type.Value}
        case 'Sv'
            c_disp=pow2db_perso(out.Sv_mean_lin);
            v_disp=pow2db_perso(nanmean(out.Sv_mean_lin,2));
            h_disp=pow2db_perso(nanmean(out.Sv_mean_lin,1));
            ty='sv';
            c_disp(isnan(c_disp))=-999;
        case 'PRC'
            c_disp=(out.PRC)*100;
            v_disp=(nanmean(out.PRC,2))*100;
            h_disp=(nanmean(out.PRC,1))*100;
            ty='prc';
        case 'Std Sv'
            c_disp=(out.Sv_dB_std);
            v_disp=(nanmean(out.Sv_dB_std,2));
            h_disp=(nanmean(out.Sv_dB_std,1));
            ty='std_sv';
        case 'Nb Samples'
            c_disp=(out.nb_samples);
            v_disp=(nanmean(c_disp,2));
            h_disp=(nanmean(c_disp,1));
            ty='nb_samples';
        case 'Nb Tracks'
            c_disp=(out.nb_tracks);
            v_disp=(nanmean(c_disp,2));
            h_disp=(nanmean(c_disp,1));
            ty='nb_st_tracks';
        case'Nb Single Targets'
            c_disp=(out.nb_st);
            v_disp=(nanmean(c_disp,2));
            h_disp=(nanmean(c_disp,1));
            ty='nb_st_tracks';
        case 'Tag'
            [legend_str,~,ib]=unique(out.Tags);
            c_disp=reshape(ib,s_eint);
            v_disp=(nanmean(c_disp,2));
            h_disp=(nanmean(c_disp,1));
            ty='tag';
    end
    
    
    c_disp=gather(c_disp);
    v_disp=gather(v_disp);
    h_disp=gather(h_disp);
    
    
    xlim=[nanmin(x_disp(:)) nanmax(x_disp(:))];
    ylim=[nanmin(y_disp_tmp(:)) nanmax(y_disp_tmp(:))];
else
    out=[];
    ylim=[nan nan];
    xlim=[nan nan];
end
if ~isempty(out)
    
    %figure();pcolor(x_disp,y_disp,c_disp);axis ij ;y_ticks=get(gca,'ytick');y_labels=get(gca,'YTickLabel');
    x_labels{1}='';
    y_labels{1}='';
    set(echo_int_tab_comp.main_plot,'Xdata',x_disp,'YData',y_disp,'Zdata',c_disp,'Cdata',c_disp,'alphadata',ones(size(c_disp)),'userdata',ty);
    set(echo_int_tab_comp.v_plot,'xdata',v_disp,'ydata',nanmean(y_disp,2));
    set(echo_int_tab_comp.h_plot,'ydata',h_disp,'xdata',nanmean(x_disp,1));
    set(echo_int_tab_comp.main_ax,'xtick',x_ticks,'ytick',y_ticks);
    yl=[prctile(h_disp,10) nanmax(h_disp)*(1+sign(nanmax(h_disp))*0.1)];
    if diff(yl)>0
        set(echo_int_tab_comp.h_ax,'ylim',yl);
    end
    xl=[prctile(v_disp,10) nanmax(v_disp)*(1+sign(nanmax(v_disp))*0.1)];
    if diff(xl)>0
        set(echo_int_tab_comp.v_ax,'xlim',xl);
    end
    set(echo_int_tab_comp.h_ax,'XTickLabel',x_labels);
    set(echo_int_tab_comp.v_ax,'YTickLabel',y_labels);
    set(echo_int_tab_comp.main_ax,'xlim',xlim,'ylim',ylim);
    
    update_echo_int_alphamap(main_figure);
    if ~isempty(legend_str)
        echo_int_tab_comp.cbar.YTick=unique(ib);
        echo_int_tab_comp.cbar.YTickLabel=cellstr(legend_str);
    else
        echo_int_tab_comp.cbar.TicksMode='auto';
        echo_int_tab_comp.cbar.TickLabelsMode='auto';
    end
    
else
    reset_plot(echo_int_tab_comp);
end

setappdata(main_figure,'EchoInt_tab',echo_int_tab_comp);
end

function reset_plot(echo_int_tab_comp)
set(echo_int_tab_comp.main_plot,'Xdata',[0 0;0 0],'YData',[0 0;0 0],'CData',[0 0;0 0],'Zdata',[0 0;0 0],'alphadata',ones(size([0 0;0 0])));
set(echo_int_tab_comp.h_plot,'Xdata',0,'YData',0);
set(echo_int_tab_comp.v_plot,'Xdata',0,'YData',0);
set(echo_int_tab_comp.h_ax,'XTickLabel',{});
set(echo_int_tab_comp.v_ax,'YTickLabel',{});
end