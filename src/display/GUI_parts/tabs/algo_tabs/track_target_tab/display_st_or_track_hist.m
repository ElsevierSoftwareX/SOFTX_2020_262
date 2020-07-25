function display_st_or_track_hist(main_figure,ax,ax_pdf,pc_pdf,disp_var)
layer=get_current_layer();


curr_disp=get_esp3_prop('curr_disp');

survey_options_obj=layer.get_survey_options();

[trans_obj,~]=layer.get_trans(curr_disp);

[idx_alg,alg_found]=find_algo_idx(trans_obj,'SingleTarget');
db_res=1;
if alg_found
    varin=trans_obj.Algo(idx_alg).input_params_to_struct();
    xl=[varin.TS_threshold varin.TS_threshold_max];
    nb_bin=abs(diff(xl)/db_res);
else
    nb_bin=25;
    xl=curr_disp.getCaxField('singletarget');
end

if isempty(ax)
    hfig=new_echo_figure(main_figure,'tag','track_histo');
    tt=sprintf('Track from %.0f kHz',curr_disp.Freq/1e3);
    ax=axes(hfig);
    title(ax,tt);
    grid(ax,'on');
    xlabel(ax,'TS(dB)');
    grid(ax,'on');
end

for i=1:length(disp_var)
    obj=findobj(ax,'Tag',disp_var{i});
    delete(obj);
end


%   set(ax,'YTickLabel','');
if isempty(trans_obj)
    return;
end
ST = trans_obj.ST;

alpha=[1 0.5];
legend_str=cell(1,length(disp_var));
if isempty(ST)
    return;
else
    for i=1:length(disp_var)
        TS=[];
        switch disp_var{i}
            case 'st'
                TS = ST.TS_comp;
                col='r';
                legend_str{i}='Single Targets';
            case 'tracks'
                tracks = trans_obj.Tracks;
                
                if isempty(tracks)
                    continue;
                end
                
                if isempty(tracks.target_id)
                    continue;
                end
                
                col='b';
                legend_str{i}='Tracked Targets';
                for k=1:length(tracks.target_id)
                    idx_targets=tracks.target_id{k};
                    TS=[TS ST.TS_comp(idx_targets)];
                end
        end
        try
            if ~isempty(TS)
                [pdf_temp,x_temp]=pdf_perso(TS,'bin',nb_bin);
                bar(ax,x_temp,pdf_temp,'Tag',disp_var{i},'FaceColor',col,'FaceAlpha',alpha(i));
            else
                legend_str{i}=[];
            end
            if diff(xl)>0
                xlim(ax,xl);
            end
        end
        
    end
    if ~all(cellfun(@isempty,legend_str))
        legend_str(cellfun(@isempty,legend_str))=[];
        legend(ax,legend_str);
    end
end

if ~isempty(ax_pdf)&&~isempty(pc_pdf)
    
    tt_table = trans_obj.ST;
    
    if isempty(trans_obj.ST)||all(isnan(tt_table.Track_ID))
        set(pc_pdf,'XData',zeros(2,2),'YData',zeros(2,2),'CData',zeros(2,2),'ZData',zeros(2,2),'AlphaData',zeros(2,2));
        return;
    end
    
    [idx_alg,alg_found]=find_algo_idx(trans_obj,'SingleTarget');
    
    if alg_found
        varin=trans_obj.Algo(idx_alg).input_params_to_struct();
        xl=[varin.TS_threshold varin.TS_threshold_max];
    else
        xl=curr_disp.getCaxField('singletarget');
    end
    
    uu=findgroups(tt_table.Track_ID);
    
    mean_TS_per_track=splitapply(@(x) pow2db(mean(db2pow(x))),tt_table.TS_comp,uu);
    switch pc_pdf.Tag
        case 'transducer'
            mean_range_per_track=splitapply(@(x) mean(x),tt_table.Target_range,uu);
            ydir='reverse';
        case 'bottom'
            mean_range_per_track=splitapply(@(x) mean(x),tt_table.Target_range_to_bottom,uu);
            ydir='normal';
    end
    [cmap,col_ax,~,col_grid,~,~,~]=init_cmap(curr_disp.Cmap);
    set(ax_pdf,'GridColor',col_grid,'Color',col_ax);
    %figure();
    %histogram2(mean_TS_per_track,mean_range_per_track,[numel((xl(1):db_res:xl(2))) numel((0:survey_options_obj.Horizontal_slice_size:nanmax(mean_range_per_track)))],'FaceColor','flat','DisplayStyle','tile');
    [pdf,x_mat,y_mat]=pdf_2d_perso(mean_TS_per_track,mean_range_per_track,(xl(1):db_res:xl(2))',(0:survey_options_obj.Horizontal_slice_size:nanmax(mean_range_per_track)),'gauss');
    cax=[prctile(pdf(pdf>0),5) prctile(pdf(pdf>0),95)];
    try
        set(pc_pdf,'XData',x_mat,'YData',y_mat,'CData',pdf,'ZData',zeros(size(pdf)),'AlphaData',pdf>=cax(1),'EdgeColor',col_grid);
    catch err
        print_errors_and_warnings(main_figure,'warning','Could not update track histogram');
        print_errors_and_warnings(main_figure,'warning',err);
    end
    
    ax_pdf.YDir=ydir;
    
    xl = [nanmin(x_mat(:)) nanmax(x_mat(:))];
    
    yl = [nanmin(y_mat(:)) nanmax(y_mat(:))];
    
    if diff(xl)>0
        ax_pdf.XLim=xl;
    end
    if diff(yl)>0
        ax_pdf.YLim=yl;
    end
    if diff(cax)>0
        caxis(ax_pdf,cax);
    end
    
    colormap(ax_pdf,cmap);
    
end





end